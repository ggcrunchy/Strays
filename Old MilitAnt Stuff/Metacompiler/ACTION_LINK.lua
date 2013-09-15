--- Action link from C++.

--[[
--
--
-- ActionLink.h
--
--
#ifndef _ACTION_LINK_CL
#define _ACTION_LINK_CL

// Forward references
struct lua_State;

template<typename T> struct InvokeContext;

class ActionNode_cl;

/// Manages a link to one or more context-enhanced action nodes
class ActionLink_cl : public IVObjectComponent {
public:
	ActionLink_cl (void);

	void Invoke (VisTypedEngineObject_cl * pObject = NULL, bool bIsProxy = false);
	void Invoke (int choice, VisTypedEngineObject_cl * pObject = NULL, bool bIsProxy = false);

	static void Trip (lua_State * L, ActionNode_cl * pNode, const VisTriggerSourceComponent_cl * pSource);

	/// Payload sent to @b "follow_up:action" alerts
	struct FollowUpArgs {
		FollowUpArgs (const ActionLink_cl * pInvokee, const VisTypedEngineObject_cl * pObject, int choice) : mInvokee(pInvokee), mObject(pObject), mChoice(choice) {}

		const ActionLink_cl * mInvokee;	///< Action link that was invoked
		const VisTypedEngineObject_cl * mObject;///< Object passed as argument to actions, bookends, and follow-up
		int mChoice;///< Choice passed as argument to follow-up (may be < 0)
	};

	V_DECLARE_SERIAL_DLLEXP(ActionLink_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(ActionLink_cl)

	void ListEpilogue (void) { mFlags.SetBit(eListEpilogue); }
	void ListPrologue (void) { mFlags.SetBit(eListPrologue); }

private:
	enum {
		eHasCalledEpilogue,	///< Flag indicating whether CallEpilogue() has been called at least once by this link
		eHasCalledPrologue,	///< Flag indicating whether CallPrologue() has been called at least once by this link
		eInvoked,	///< Flag indicating whether Invoke() has been called at least once through this link
		eListEpilogue,	///< Flag indicating whether to make an epilogue listing, if possible
		eListPrologue,	///< Flag indicating whether to make a prologue listing, if possible
		_nFlagBits	///< How many flag bits were enumerated
	};

	void CallBookend (lua_State * L, VisTypedEngineObject_cl * pObject, bool bIsProxy, int choice, int pos, int flag_bit, bool bList);
	void CallEpilogue (lua_State * L, VisTypedEngineObject_cl * pObject, bool bIsProxy, int choice);
	void CallPrologue (lua_State * L, VisTypedEngineObject_cl * pObject, bool bIsProxy, int choice);
	void CollectNodeTargets (void);

	static void CallAction (lua_State * L, InvokeContext<ActionLink_cl> * pContext, ActionNode_cl * pNode, VisTypedEngineObject_cl * pObject);

	VPListT<VisTriggerTargetComponent_cl> mTargets;	///< @b "Do" targets harvested from nodes (via @e mSource) where this link was plugged
	VSmartPtr<VisTriggerSourceComponent_cl> mSource;///< Cached trigger source associated with link
	VTBitfield<32> mFlags;	///< Has-called, invoked, and listing flags
};

#endif
--]]

--[[
--
--
-- ActionLink.cpp
--
--
#include "stdafx.h"
#include "actionlink.h"
#include "actionnode.h"
#include "entityhelpers.h"
#include "entitylinks.h"
#include <vScript/VScriptManager.hpp>

/// Invocation state to preserve for Trip() calls
struct ActionInvokeContext : InvokeContext<ActionLink_cl> {
	VPListT<VisTriggerSourceComponent_cl> mContinueList;///< List used to collect @b "Continue" sources in order to delay firing them until after follow-up
};

/* Static bindings */
InvokeContext<ActionLink_cl> * InvokeContext<ActionLink_cl>::sCurrent = NULL;

/// Constructor
ActionLink_cl::ActionLink_cl (void) : mFlags(_nFlagBits)
{
	Initialize();
}

/// Serialization
void ActionLink_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = BeginComponentSerialize(this, ar, VERSION);
}

/// Builds up some context and then does:
/// - Performs any prologue
/// - Calls Trip() on each linked action node
///	- Sends a @b "follow_up:action" alert to the link owner, with a FollowUpArgs * as @e iParamB
/// - Performs any epilogue
/// - Fires any "continue" trigger sources from the tripped nodes
///
/// @param pObject Object passed as input to the action
/// @param bIsProxy If @b true, a proxy of @a pObject is passed in lieu of the raw pointer
/// @remark The @e choice is assumed to be @b -1
void ActionLink_cl::Invoke (VisTypedEngineObject_cl * pObject, bool bIsProxy)
{
	Invoke(-1, pObject, bIsProxy);
}

/// Variant of Invoke()
/// @param choice User-defined choice associated with the action, e.g. index for some current behavior
/// @param pObject Object passed as input to the action
/// @param bIsProxy If @b true, a proxy of @a pObject is passed in lieu of the raw pointer
void ActionLink_cl::Invoke (int choice, VisTypedEngineObject_cl * pObject, bool bIsProxy)
{
	VASSERT(GetOwner());

	if (Vision::Editor.IsInEditor()) return;

	// On the first invocation, cache the trigger source. Harvest any action nodes to which
	// it points, breaking their links to establish fine control over how they fire.
	if (IsFirstInstance(mFlags, eInvoked))
	{
		mSource = FindSource(GetOwner(), GetComponentName());

		if (mSource) CollectNodeTargets();
	}

	// Begin by triggering any targets still linked to the source.
	if (mSource) mSource->TriggerAllTargets();

	// Choose the input object and set up a trip context.
	ActionInvokeContext context;

	context.mLink = this;
	context.mObject = pObject ? pObject : GetOwner();
	context.mIsProxy = pObject ? bIsProxy : false;

	// Call any prologue logic registered to the compile context.
	CallPrologue(VScriptRM()->GetMasterState(), context.mObject, context.mIsProxy, choice);

	// Trip each of the link's action nodes.
	for (int i = 0; i < mTargets.GetLength(); ++i) mTargets.GetPtrs()[i]->OnTrigger(mSource);

	// Alert the link owner, allowing it to do any follow-up now that all actions are done.
	SendAlert(GetOwner(), "follow_up:action", &FollowUpArgs(this, context.mObject, choice));

	// Call any epilogue logic registered to the compile context.
	CallEpilogue(VScriptRM()->GetMasterState(), context.mObject, context.mIsProxy, choice);

	// Fire all "continue" sources put on the to-do list during tripping.
	context.mContinueList.RemoveFlagged();

	for (int i = 0; i < context.mContinueList.GetLength(); ++i) context.mContinueList.GetPtrs()[i]->TriggerAllTargets();
}

/// Logic common to prologue and epilogue calls
/// @param pObject Object passed as input to the action
/// @param bIsProxy If @b true, a proxy of @a pObject is passed in lieu of the raw pointer
/// @param choice Choice that was passed to action, q.v. Invoke()
/// @param pos Stack index of auxiliary @b metacompiler function
/// @param flag_bit Bit index for "has-been-called" flag
/// @param bList If @b true, a listing is made of the bookend, if a fresh function was compiled
void ActionLink_cl::CallBookend (lua_State * L, VisTypedEngineObject_cl * pObject, bool bIsProxy, int choice, int pos, int flag_bit, bool bList)
{
	bool bIsFirst = IsFirstInstance(mFlags, flag_bit);

	PushFirstArgs(L, this, bIsFirst ? GetComponentName() : NULL, pObject, bIsProxy);// ..., call, pLink, name_or_nil, object_or_proxy

	lua_pushinteger(L, choice);	// ..., call, pLink, name_or_nil, object_or_proxy, choice
	lua_pushlightuserdata(L, GetOwner()->GetTypeId());	// ..., call, pLink, name_or_nil, object_or_proxy, choice, type

	if (bList) lua_pushboolean(L, true);// ..., call, pLink, name_or_nil, object_or_proxy, choice, type, true

	CallFromStack(L, pos);	// ...
}

/// Logic called after the action
/// @param pObject Object passed as input to the action
/// @param bIsProxy If @b true, a proxy of @a pObject is passed in lieu of the raw pointer
/// @param choice Choice that was passed to the action, q.v. Invoke()
void ActionLink_cl::CallEpilogue (lua_State * L, VisTypedEngineObject_cl * pObject, bool bIsProxy, int choice)
{
	static bool sCallEpilogue;

	int pos = BindAndPushFuncRef(L, sCallEpilogue, "metacompiler.CallEpilogue");// ..., call

	CallBookend(L, pObject, bIsProxy, choice, pos, eHasCalledEpilogue, mFlags.IsBitSet(eListEpilogue));	// ...
}

/// Logic called before the action
/// @param pObject Object passed as input to the action
/// @param bIsProxy If @b true, a proxy of @a pObject is passed in lieu of the raw pointer
/// @param choice Choice that was passed to the action, q.v. Invoke()
void ActionLink_cl::CallPrologue (lua_State * L, VisTypedEngineObject_cl * pObject, bool bIsProxy, int choice)
{
	static bool sCallPrologue;

	int pos = BindAndPushFuncRef(L, sCallPrologue, "metacompiler.CallPrologue");// ..., call

	CallBookend(L, pObject, bIsProxy, choice, pos, eHasCalledPrologue, mFlags.IsBitSet(eListPrologue));	// ...
}

/// Commandeers any links to action nodes for direct control
void ActionLink_cl::CollectNodeTargets (void)
{
	for (int i = 0; i < mSource->m_Targets.Count(); ++i)
	{
		VisTriggerTargetComponent_cl * pTarget = (VisTriggerTargetComponent_cl *)mSource->m_Targets.GetPtrs()[i];

		if (!pTarget || !pTarget->GetOwner()) continue;

		if (pTarget->GetOwner()->IsOfType(V_RUNTIME_CLASS(ActionNode_cl)))
		{
			mTargets.Append(pTarget);

			IVisTriggerBaseComponent_cl::OnUnlink(mSource, pTarget);
		}
	}
}

/// Core routine that calls the action loaded into a node, then fires or collects any "continue" source
/// @param pNode Tripped node
/// @param pSource Trigger that tripped the node
/// @remark The "can trip" condition is evaluated before any action is called. If it fails,
/// the next node is tried, and so on, until one is found. If there are no more nodes, the
/// function exits.
/// @remark A node may be tripped directly via a trigger source, though it loses some link-based
/// context it would get from Invoke(). In this case, the owner of @a pSource is treated
/// as the input object, and is not passed as a proxy.
/// @remark The "can trip" condition takes the same input object and proxy flag as the action
void ActionLink_cl::Trip (lua_State * L, ActionNode_cl * pNode, const VisTriggerSourceComponent_cl * pSource)
{
	VASSERT(pSource);
	VASSERT(pSource->GetOwner());

	// Cache any current context in case nested invocations follow.
	ActionInvokeContext * pContext = (ActionInvokeContext *)InvokeContext<ActionLink_cl>::sCurrent;

	// Choose the input object.
	VisTypedEngineObject_cl * pObject = pContext ? pContext->mObject : pSource->GetOwner();

	// Narrow down to a node, starting from the input node, and call its action. If the
	// final node wants to try again, repeat starting from that node.
	do {
		// If the linked node cannot be tripped, try the next one in the chain, continuing
		// until a valid node is found. If no node is available, quit.
		while (!pNode->CanTrip(pObject, pContext ? pContext->mIsProxy : false))
		{
			pNode = pNode->GetNext();

			if (!pNode) return;
		}

		// Call the action logic.
		CallAction(L, pContext, pNode, pObject);
	} while (pNode->ShouldTryAgain());

	// Deal with the "continue" source, if the node has one. If the node was tripped via
	// a link, add it to the link's to-do list; otherwise, just fire the source.
	VisTriggerSourceComponent_cl * pContinue = pNode->GetContinueSource();

	if (pContinue)
	{
		if (pContext) pContext->mContinueList.Append(pContinue);

		else pContinue->TriggerAllTargets();
	}
}

/// Logic that actually runs the action
/// @param pContext Invocation context
/// @param pNode Node used to lookup and run action
/// @param pObject Object passed as input to the action
void ActionLink_cl::CallAction (lua_State * L, InvokeContext<ActionLink_cl> * pContext, ActionNode_cl * pNode, VisTypedEngineObject_cl * pObject)
{
	static bool sCallAction;

	int pos = BindAndPushFuncRef(L, sCallAction, "metacompiler.CallAction");// ..., call

	// Pass along various bits of context, when available: whether the input object is a
	// proxy, the name of the link's action, and also the owner's type. The link's address
	// is passed along for the node to use as a unique lookup key to the compiled action.
	if (pContext)
	{
		VASSERT(pObject == pContext->mObject);

		ActionLink_cl * pLink = pContext->mLink;

		PushFirstArgs(L, pNode, pLink->GetComponentName(), pObject, pContext->mIsProxy);// ..., call, pNode, name_or_nil, object_or_proxy

		lua_pushlightuserdata(L, pLink);// ..., call, pNode, name_or_nil, object_or_proxy, key
		lua_pushlightuserdata(L, pLink->GetOwner()->GetTypeId());	// ..., call, pNode, name_or_nil, object_or_proxy, key, type
	}

	// Otherwise, add no context. The trigger source's owner is provided as lookup key.
	else
	{
		PushFirstArgs(L, pNode, NULL, pObject, false);	// ..., call, pNode, nil, object

		lua_pushlightuserdata(L, pObject);	// ..., call, pNode, nil, object, key
		lua_pushnil(L);	// ..., call, pNode, nil, object, key, nil
	}
 
	lua_pushboolean(L, pNode->MakeListing());	// ..., call, pNode, name_or_nil[, object_or_proxy], key, type_or_nil, make_listing

	CallFromStack(L, pos);	// ...
}

/* ActionLink_cl variables */
V_IMPLEMENT_SERIAL(ActionLink_cl, IVObjectComponent, 0, Vision::GetEngineModule());

START_VAR_TABLE(ActionLink_cl, IVObjectComponent, "Context-aware action link", VFORGE_HIDECLASS, "Action link")

END_VAR_TABLE
--]]