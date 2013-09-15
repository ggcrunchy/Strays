--- Action node from C++.

--[[
--
--
-- ActionNode.h
--
--
#ifndef _ACTION_NODE_CL
#define _ACTION_NODE_CL

// Forward references
struct lua_State;

class ConditionLink_cl;

/// Game state-based side effects that may be linked to actions
class ActionNode_cl : public VisBaseEntity_cl {
public:
	ActionNode_cl (void);

	VOVERRIDE void InitFunction (void);
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);

	ActionNode_cl * GetNext (void) const;

	bool CanTrip (VisTypedEngineObject_cl * pObject, bool bIsProxy);

	V_DECLARE_SERIAL_DLLEXP(ActionNode_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(ActionNode_cl)

	bool MakeListing (void) const { return ShouldMakeListing != FALSE; }
	bool ShouldTryAgain (void) const { return TryAgain != FALSE; }

	VisTriggerSourceComponent_cl * GetContinueSource (void) { return mContinue; }

private:
	void Push (lua_State * L);

	// vForge variables
	VString Expression;	///< Condition expression (cf. CompoundConditionNode_cl), as alternative to node link
	BOOL ShouldMakeListing;	///< If true and possible, a code listing is generated when this node is tripped
	BOOL TestObject;///< If true and doing the "can trip" test, pass the object as input to the test
	BOOL TryAgain;	///< If true, try this node again after tripping once
public:	// <- hack
	// Implementation
	VSmartPtr<VisTriggerSourceComponent_cl> mContinue;	///< Can be used to chain other triggers after doing the action, e.g. for game state-dependent events
	VSmartPtr<VisTriggerTargetComponent_cl> mDo;///< Target to do an action
	VSmartPtr<ConditionLink_cl> mCanTrip;	///< Link for condition: can this node be tripped?
	__int64 mNextActionNodeID;	///< If the condition is evaluated and fails, the next action to try
};

#endif
--]]

--[[
--
--
-- ActionNode.cpp
--
--
#include "stdafx.h"
#include "actionnode.h"
#include "actionlink.h"
#include "conditionlink.h"
#include "action_components/actioncomponents.h"
#include "condition_components/conditioncomponents.h"
#include "entitylinks.h"
#include "entityhelpers.h"
#include <vScript/VScriptManager.hpp>

/// Constructor
ActionNode_cl::ActionNode_cl (void) : mNextActionNodeID(0)
{
}

/// Initialization
void ActionNode_cl::InitFunction (void)
{
	VisBaseEntity_cl::InitFunction();

	if (!Vision::Editor.IsInEditor()) SetVisibleBitmask(VIS_ENTITY_INVISIBLE);

	AssignNamedComponent(this, mContinue, "Continue", VIS_OBJECTCOMPONENTFLAG_SERIALIZEWHENRELEVANT);
	AssignNamedComponent(this, mDo, "Do", VIS_OBJECTCOMPONENTFLAG_SERIALIZEWHENRELEVANT);

	static bool sRegistered;

	OnNewInstance(this, sRegistered);
}

/// Message handler
void ActionNode_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	static LinkComponentData sLinks[] = {
		LINK_DATA_EX(ActionNode_cl, CanTrip, "Can this node be tripped?", NULL)
	};

	lua_State * L = VScriptRM()->GetMasterState();

	switch (iID)
	{
	// Trigger: iParamA = VisTriggerSourceComponent_cl *, iParamB = VisTriggerTargetComponent_cl *
	case VIS_MSG_TRIGGER:
		VASSERT(INT_PTR(mDo.GetPtr()) == iParamB);

		ActionLink_cl::Trip(L, this, (VisTriggerSourceComponent_cl *)iParamA);

		break;

	// New Instance: iParamA = BOOL
	case ID_OBJECT_NEW_INSTANCE:
		ConditionLink_cl::SetupTargets(this, sLinks);

		break;

	// Alert: iParamA = const char * or NULL, iParamB = const void * or NULL
	case ID_OBJECT_ALERT:
		if (StrComp(iParamA) == "push") Push(L);

		break;

	// Validate export: iParamA = VisBeforeSceneExportedObject_cl *
	case ID_OBJECT_VALIDATE_EXPORT:
//		Validate(iParamA);

		break;

	// Other cases
	default:
		// Get Links: iParamA = VShapeLinkConfig *
		if (VIS_MSG_EDITOR_GETLINKS == iID)
		{
			LinkBuilder lb(iParamA);

			/* Targets */
			lb	.AddTarget(V_RUNTIME_CLASS(ActionNode_cl), "attach_from_node", "Link from previous node");

			/* Sources */
			lb	.AddSource(&mNextActionNodeID, "attach_to_next_node", "Link to next node");

			ConditionLink_cl::Configure(sLinks, iParamA);
		}

		// Can Link / On Link / On Unlink: iParamA = VShapeLink *
		else
		{
			ConditionLink_cl::ManageLinkTo(this, iID, iParamA);

			ManageTypeLink(iID, iParamA, V_RUNTIME_CLASS(ActionNode_cl));
			ManageTypeLinkID(iID, iParamA, V_RUNTIME_CLASS(ActionNode_cl), mNextActionNodeID);
		}

		VisBaseEntity_cl::MessageFunction(iID, iParamA, iParamB);
	}
}

/// Serialization
void ActionNode_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = BeginEntitySerialize(this, ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Expression;
		ar >> ShouldMakeListing;
		ar >> TestObject;
		ar >> TryAgain;
		ar >> mNextActionNodeID;
	}

	else
	{
		/* VERSION 1 */
		ar << Expression;
		ar << ShouldMakeListing;
		ar << TestObject;
		ar << TryAgain;
		ar << mNextActionNodeID;
	}
}

/// @return Pointer to next action node, or @b NULL if absent
ActionNode_cl * ActionNode_cl::GetNext (void) const
{
	if (!mNextActionNodeID) return NULL;

	VisBaseEntity_cl * pEntity = VisBaseEntity_cl::FindByUniqueID(mNextActionNodeID);

	VASSERT(pEntity && pEntity->IsOfType(V_RUNTIME_CLASS(ActionNode_cl)));

	return (ActionNode_cl *)pEntity;
}

/// @param pObject Object passed as input to the condition
/// @param bIsProxy If @b true, a proxy of @a pObject is passed in lieu of the raw pointer
/// @return If true, this node can be tripped
/// @remark If the @e TestObject flag is off, @a pObject is treated as @b NULL and @a bIsProxy as @b false
bool ActionNode_cl::CanTrip (VisTypedEngineObject_cl * pObject, bool bIsProxy)
{
	return mCanTrip->Invoke(Expression, TestObject ? pObject : NULL, TestObject ? bIsProxy : false);
}

/// Metacompiler push logic
/// @remark Action components pushed onto stack
void ActionNode_cl::Push (lua_State * L)
{
	for (int i = 0; i < Components().Count(); ++i)
	{
		IVObjectComponent * pComp = Components().GetPtrs()[i];

		if (pComp && pComp->IsOfType(V_RUNTIME_CLASS(ActionComponent_cl))) lua_pushlightuserdata(L, pComp);	// ..., pComp
	}
}

/* ActionNode_cl variables */
V_IMPLEMENT_SERIAL(ActionNode_cl, VisBaseEntity_cl, 0, &gGameModule);

START_VAR_TABLE(ActionNode_cl, VisBaseEntity_cl, "Side effects that may be tied to an action", VVARIABLELIST_FLAGS_NONE, "Models/action_node.MODEL")

	DEFINE_VAR_VSTRING(ActionNode_cl, Expression, "Expression used to glue together condition components", "", 0, 0, 0);
	DEFINE_VAR_BOOL(ActionNode_cl, ShouldMakeListing, "Should a code listing be made when compiling against this node?", "FALSE", 0, 0);
	DEFINE_VAR_BOOL(ActionNode_cl, TestObject, "If doing \"can trip\" tests, should the action object be considered?", "TRUE", 0, 0);
	DEFINE_VAR_BOOL(ActionNode_cl, TryAgain, "Try to trip this node again after tripping it?", "FALSE", 0, 0);

END_VAR_TABLE
--]]