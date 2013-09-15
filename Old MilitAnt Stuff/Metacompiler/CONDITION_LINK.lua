--- Condition link from C++.

--[[
--
--
-- ConditionLink.h
--
--
#ifndef _CONDITION_LINK_CL
#define _CONDITION_LINK_CL

// Forward references
struct lua_State;
struct LinkComponentData;

template<typename T> struct InvokeContext;

class ConditionNodeBase_cl;

/// Manages a link to a context-enhanced condition node
class ConditionLink_cl : public IVObjectComponent {
public:
	ConditionLink_cl (void);

	bool Invoke (VisTypedEngineObject_cl * pObject = NULL, bool bIsProxy = false);
	bool Invoke (const VString & expr, VisTypedEngineObject_cl * pObject = NULL, bool bIsProxy = false);

	void SetDefault (bool bDefault) { mDefault = bDefault; }
	
	static bool Trip (lua_State * L, ConditionNodeBase_cl * pNode, VisTypedEngineObject_cl * pObject = NULL);

	static void ManageLinkFrom (VisTypedEngineObject_cl * pObject, int iID, INT_PTR iParam);
	static void ManageLinkTo (VisTypedEngineObject_cl * pObject, int iID, INT_PTR iParam);

	V_DECLARE_SERIAL_DLLEXP(ConditionLink_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(ConditionLink_cl)

	/// Editor-side link configuration
	template<int count> static void Configure (LinkComponentData (&links)[count], INT_PTR iParam)
	{
		ConfigureFromData(links, count, iParam);
	}

	/// Adds and registers missing condition link targets, as well as registering those already present
	template<int count> static void SetupTargets (VisTypedEngineObject_cl * pObject, LinkComponentData (&links)[count])
	{
		SetupLinkTargets<ConditionLink_cl>(pObject, links);
	}

	/// Payload sent to @b "follow_up:condition" alerts
	struct FollowUpArgs {
		FollowUpArgs (const ConditionLink_cl * pInvokee, const VisTypedEngineObject_cl * pObject, bool & bPass) : mInvokee(pInvokee), mObject(pObject), mPass(bPass) {}

		const ConditionLink_cl * mInvokee;	///< Condition link that was invoked
		const VisTypedEngineObject_cl * mObject;///< Object passed as argument to conditions and follow-up
		bool & mPass;	///< Current result of evaluation; may be overridden by follow-up
	};

private:
	static void CallCondition (lua_State * L, InvokeContext<ConditionLink_cl> * pContext, ConditionNodeBase_cl * pNode, VisTypedEngineObject_cl * pObject);
	static void ConfigureFromData (LinkComponentData * links, int count, int iParam);

	ConditionNodeBase_cl * mNode;	///< Cached node object
public:	// <- hack
	__int64 mNodeID;///< Node to which link is linked, if any
	bool mDefault;	///< Default result if no node is bound
	bool mInvoked;	///< If true, Invoke() has been called at least once through this link
};

#endif
--]]

--[[
--
--
-- ConditionLink.cpp
--
--
#include "stdafx.h"
#include "conditionlink.h"
#include "conditionnode.h"
#include "entityhelpers.h"
#include "entitylinks.h"
#include <vScript/VScriptManager.hpp>

/// Invocation state to preserve for Trip() calls
typedef struct InvokeContext<ConditionLink_cl> ConditionInvokeContext;

/* Static bindings */
ConditionInvokeContext * ConditionInvokeContext::sCurrent = NULL;

/// Constructor
ConditionLink_cl::ConditionLink_cl (void) : mNode(NULL), mNodeID(0), mDefault(true), mInvoked(false)
{
	Initialize();
}

/// Serialization
void ConditionLink_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = BeginComponentSerialize(this, ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> mNodeID;
	}

	else
	{
		/* VERSION 1 */
		ar << mNodeID;
	}
}

/// Variant of Invoke()
/// @param pObject Object passed as input to the condition
/// @param bIsProxy If @b true, a proxy of @a pObject is passed in lieu of the raw pointer
/// @return Condition result; if no node is linked, @b true
bool ConditionLink_cl::Invoke (VisTypedEngineObject_cl * pObject, bool bIsProxy)
{
	return Invoke(VString(), pObject, bIsProxy);
}

///
/// @param expr
/// @param pObject Object passed as input to the condition
/// @param bIsProxy If @b true, a proxy of @a pObject is passed in lieu of the raw pointer
/// @return Condition result; if no node is linked and @a expr is empty, @b true
bool ConditionLink_cl::Invoke (const VString & expr, VisTypedEngineObject_cl * pObject, bool bIsProxy)
{
	VASSERT(GetOwner());

	if (Vision::Editor.IsInEditor()) return true;

	// Choose the input object and set up a trip context.
	ConditionInvokeContext context;

	context.mLink = this;
	context.mObject = pObject ? pObject : GetOwner();
	context.mIsProxy = pObject ? bIsProxy : false;

	// On the first invocation, resolve the linked condition node. If an ID is present,
	// link to the node it indexes. Otherwise, if a non-empty expression was provided,
	// use it to assemble a node internally from the owner's condition components.
	if (IsFirstInstance(mInvoked))
	{
		if (mNodeID) mNode = (ConditionNodeBase_cl *)VisBaseEntity_cl::FindByUniqueID(mNodeID);

		else if (!expr.IsEmpty()) mNode = CompoundConditionNode_cl::FromObject(GetOwner(), expr);

		VASSERT(!mNodeID || mNode);
	}

	// If a node exists, trip it and save the result. Otherwise, use the default.
	bool bPass = mNode ? Trip(VScriptRM()->GetMasterState(), mNode) : mDefault;

	// Alert the link owner, allowing it to do any follow-up such as overriding the pass
	// boolean, now that any condition is done. Return the boolean as the result.
	SendAlert(GetOwner(), "follow_up:condition", &FollowUpArgs(this, context.mObject, bPass));

	return bPass;
}

///
/// @param pNode
/// @param pObject Object passed as input to the condition
bool ConditionLink_cl::Trip (lua_State * L, ConditionNodeBase_cl * pNode, VisTypedEngineObject_cl * pObject)
{
	VASSERT(pNode);

	// Cache any current context in case nested invocations follow.
	ConditionInvokeContext * pContext = ConditionInvokeContext::sCurrent;

	// Call the condition logic and interpret whatever was on the stack as a boolean result.
	CallCondition(L, pContext, pNode, pContext ? pContext->mObject : (pObject ? pObject : pNode));

	bool bPass = lua_toboolean(L, -1) != 0;

	lua_pop(L, 1);	// ...

	return bPass;
}

/// Logic that actually runs the condition
/// @param pContext Invocation context
/// @param pNode Node used to lookup and run action
/// @param pObject Object passed as input to the condition
void ConditionLink_cl::CallCondition (lua_State * L, ConditionInvokeContext * pContext, ConditionNodeBase_cl * pNode, VisTypedEngineObject_cl * pObject)
{
	static bool sCallCondition;

	int pos = BindAndPushFuncRef(L, sCallCondition, "metacompiler.CallCondition");	// ..., call

	//
	if (pContext)
	{
		ConditionLink_cl * pLink = pContext->mLink;

		PushFirstArgs(L, pNode, pLink->GetComponentName(), pObject, pContext->mIsProxy);// ..., call, pNode, name_or_nil, object_or_proxy

		lua_pushlightuserdata(L, pLink);// ..., call, pNode, name_or_nil, object_or_proxy, key
		lua_pushlightuserdata(L, pLink->GetOwner()->GetTypeId());	// ..., call, pNode, name_or_nil, object_or_proxy, key, type
	}

	//
	else
	{
		PushFirstArgs(L, pNode, NULL, pObject, false);	// ..., call, pNode, nil, object

		lua_pushlightuserdata(L, pObject);	// ..., call, pNode, nil, object, key
		lua_pushnil(L);	// ..., call, pNode, nil, object, key, nil
	}

	lua_pushboolean(L, pNode->MakeListing());	// ..., call, pNode, name_or_nil, object_or_proxy, key, type_or_nil, make_listing

	CallFromStack(L, pos, 1);	// ..., bPassed
}

///
/// @param links
/// @param count
/// @param iParam
void ConditionLink_cl::ConfigureFromData (LinkComponentData * links, int count, int iParam)
{
	VString unique_id;

	LinkBuilder lb(iParam);

	for (int i = 0; i < count; ++i)
	{
		ConditionLink_cl * pLink = (ConditionLink_cl *)links[i].mPtr;

		unique_id.Format("condition_links:%i", i);

		lb.AddSource(links[i].mOffset, unique_id, links[i].mDisplay, links[i].mIcon);
		lb.SetUserData(V_RUNTIME_CLASS(ConditionLink_cl));
		lb.AddMetadataTo(links[i]);
	}
}

///
/// @param pObject
/// @param iID
/// @param iParam [in-out]
/// @return
void ConditionLink_cl::ManageLinkFrom (VisTypedEngineObject_cl * pObject, int iID, INT_PTR iParam)
{
	if (iID != VIS_MSG_EDITOR_CANLINK) return;

	VShapeLink * pLink = (VShapeLink *)iParam;
	
	pLink->m_bResult = CountComponents(pLink->m_pOtherObject, V_RUNTIME_CLASS(ConditionLink_cl)) > 0;
}

///
/// @param pObject
/// @param iID
/// @param iParam [in-out]
/// @return
void ConditionLink_cl::ManageLinkTo (VisTypedEngineObject_cl * pObject, int iID, INT_PTR iParam)
{
	if (iID < VIS_MSG_EDITOR_CANLINK || iID > VIS_MSG_EDITOR_ONUNLINK) return;

	VShapeLink * pLink = (VShapeLink *)iParam;

	if (pLink->m_LinkInfo.GetUserData() != V_RUNTIME_CLASS(ConditionLink_cl)) return;

	ConditionLink_cl * pCondLink = *AtOffset<VSmartPtr<ConditionLink_cl> >(pObject, pLink->m_LinkInfo.m_iCustomID);

	pLink->m_LinkInfo.SetUserData(&pCondLink->mNodeID);

	ManageTypeLinkID(iID, iParam, V_RUNTIME_CLASS(ConditionNodeBase_cl), pCondLink->mNodeID);

	pLink->m_LinkInfo.SetUserData(V_RUNTIME_CLASS(ConditionLink_cl));
}

/* ConditionLink_cl variables */
V_IMPLEMENT_SERIAL(ConditionLink_cl, IVObjectComponent, 0, Vision::GetEngineModule());

START_VAR_TABLE(ConditionLink_cl, IVObjectComponent, "Context-aware condition link", VFORGE_HIDECLASS, "Condition link")

END_VAR_TABLE
--]]