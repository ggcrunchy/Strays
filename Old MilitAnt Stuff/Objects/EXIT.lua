--- Exit from C++.

--[[
--
--
-- Exit.h
--
--
#ifndef _EXIT_CL
#define _EXIT_CL

// Forward references
struct lua_State;

class ActionLink_cl;
class ConditionLink_cl;

/// An exit point from a zone
class StageExit_cl : public VisBaseEntity_cl {
public:
	StageExit_cl (void);

	VOVERRIDE void InitFunction (void);
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);
	VOVERRIDE void OnDeserializationCallback (void * pUserData) { InitFunction(); }

	VOVERRIDE VBool WantsDeserializationCallback (void) { return true; }

	V_DECLARE_SERIAL_DLLEXP(StageExit_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(StageExit_cl)

private:
	void Leave (lua_State * L);
	void Validate (INT_PTR iParam);

	// vForge variables
	BOOL EnabledWhenZoneEntered;///< If true, the exit is enabled when the zone is entered
	BOOL RemoveOnDisable;	///< If true, the exit should be removed from the scene if it becomes disabled

	// Implementation
	VSmartPtr<VisTriggerTargetComponent_cl> mDisable;	///< Target to disable this exit
	VSmartPtr<VisTriggerTargetComponent_cl> mEnable;///< Target to enable this exit
	VSmartPtr<VisTriggerTargetComponent_cl> mLeave;	///< Target to leave via the exit
	VSmartPtr<ActionLink_cl> mOnDisable;///< Link to @b On(Disable) actions
	VSmartPtr<ActionLink_cl> mOnEnable;	///< Link to @b On(Enable) actions
	VSmartPtr<ActionLink_cl> mOnLeave;	///< Link to @b On(Leave) actions
	VSmartPtr<ConditionLink_cl> mIsEnabledWhenZoneEntered;	///< Link for condition: should the exit be enabled when the zone is entered?
	__int64 mEntranceID;///< Entrance to which exit is linked, if any
	__int64 mEventID;	///< Post-exit event, if any
	bool mIsDisabled;	///< If true, this exit is disabled
};

#endif
--]]

--[[
--
--
-- Exit.cpp
--
--
#include "stdafx.h"
#include "actionlink.h"
#include "conditionlink.h"
#include "exit.h"
#include "chainevent.h"
#include "entrance.h"
#include "entitylinks.h"
#include "entityhelpers.h"
#include "game.h"
#include <vScript/VScriptManager.hpp>

/// Constructor
StageExit_cl::StageExit_cl (void) : mEntranceID(0), mEventID(0), mIsDisabled(false)
{
}

/// Initialization
void StageExit_cl::InitFunction (void)
{
	VisBaseEntity_cl::InitFunction();

#ifdef NDEBUG
	SetVisibleBitmask(VIS_ENTITY_INVISIBLE);
#endif

	static bool sRegistered;

	OnNewInstance(this, sRegistered);
}
#include "Lua_/Lua.h"
#include "Lua_/Helpers.h"
/// Message handler
void StageExit_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	static LinkComponentData sActions[] = {
		LINK_DATA_EX(StageExit_cl, OnDisable, "Exit got disabled", "Textures/Editor/e_ondisable.dds"),
		LINK_DATA_EX(StageExit_cl, OnEnable, "Exit got enabled", "Textures/Editor/e_onenable.dds"),
		LINK_DATA_EX(StageExit_cl, OnLeave, "Left via the exit", "Textures/Editor/se_onleave.dds")
	};

	static LinkComponentData sLinks[] = {
		LINK_DATA_EX(StageExit_cl, IsEnabledWhenZoneEntered, "Is exit enabled when you enter the zone?", NULL)
	};

	static LinkComponentData sTargets[] = {
		LINK_DATA_EX(StageExit_cl, Disable, "Disable the exit", "Textures/Editor/e_disable.dds"),
		LINK_DATA_EX(StageExit_cl, Enable, "Enable the exit", "Textures/Editor/e_enable.dds"),
		LINK_DATA_EX(StageExit_cl, Leave, "Leave via the exit", "Textures/Editor/se_leave.dds")
	};

	if (IsRemoved() && (VIS_MSG_TRIGGER == iID || ID_OBJECT_ALERT == iID)) return;

	lua_State * L = VScriptRM()->GetMasterState();

	// iParamA = VisTriggerSourceComponent_cl *, iParamB = VisTriggerTargetComponent_cl *
	if (VIS_MSG_TRIGGER == iID)
	{
		VisTriggerTargetComponent_cl * pTarget = (VisTriggerTargetComponent_cl *)iParamB;

		bool bManual = !iParamA;

		VASSERT(bManual || IsCommitted(this));

		/* Enable */
		if (mEnable == pTarget && (IsFlagSet_Flip(mIsDisabled) || bManual)) mOnEnable->Invoke();

		// Other automatic events are ignored if the exit is disabled.
		else if (!mIsDisabled || bManual)
		{
			/* Leave */
			if (mLeave == pTarget) mOnLeave->Invoke();

			/* Disable */
			else if (mDisable == pTarget)
			{
				mIsDisabled = true;

				mOnDisable->Invoke();

				// If requested, remove the exit when it is disabled.
				if (RemoveOnDisable) Remove();
			}
		}
	}

	// New Instance: iParamA = BOOL
	else if (ID_OBJECT_NEW_INSTANCE == iID)
	{
		SetupTriggerSources(this, sActions);
		SetupTriggerTargets(this, sTargets);

		ConditionLink_cl::SetupTargets(this, sLinks);

		mIsEnabledWhenZoneEntered->SetDefault(EnabledWhenZoneEntered != FALSE);

		/* First-time setup */
		if (iParamA) RegisterCollectionAndContext(L, V_RUNTIME_CLASS(StageExit_cl), "exits");
	}

	// Alert: iParamA = const char * or NULL, iParamB = const void * or NULL
	else if (ID_OBJECT_ALERT == iID)
	{
		/* Follow-up */
		if (StrComp(iParamA) == "follow_up:action" && mOnLeave == ((ActionLink_cl::FollowUpArgs *)iParamB)->mInvokee) Leave(L);
	}
else if (ID_OBJECT_PUBLIC_ALERT == iID)
{
	if (StriComp(iParamA) == "HUZZAH!") {
		AlertPacket * ap = (AlertPacket *)iParamB;
		Lua::GetGlobal(L, "game_state.GetStateVars");
		lua_pushliteral(L, "global");
		lua_CALL(L, 1, 1);
		lua_getfield(L, -1, "SetTrue");
		lua_pushvalue(L, -2);
		lua_pushliteral(L, "TEST");
		lua_CALL(L, 2, 0);
	};
}
	// Commit
	else if (ID_OBJECT_COMMIT == iID)
	{
		// Trip the trigger corresponding to whether the "is enabled" condition passes.
		// The early-out logic gets ignored since the trigger is being tripped manually.
		bool bDisabled = !mIsEnabledWhenZoneEntered->Invoke();

		SendTriggerMessage(this, bDisabled ? mDisable : mEnable);
	}

	// Memory state archive: iParamA = VArchive *
	else if (ID_OBJECT_MEMORY_STATE_ARCHIVE == iID)
	{
		VArchive & ar = *(VArchive *)iParamA;

		if (ar.IsLoading())
		{
			ar >> mIsDisabled;

			// TODO: What now?
		}

		else
		{
			ar << mIsDisabled;
		}
	}

	// Validate export: iParamA = VisBeforeSceneExportedObject_cl *
	else if (ID_OBJECT_VALIDATE_EXPORT == iID) Validate(iParamA);

	// Other cases
	else
	{
		// Get Links: iParamA = VShapeLinkConfig *
		if (VIS_MSG_EDITOR_GETLINKS == iID)
		{
			LinkBuilder lb(iParamA);

			lb	.AddSource(&mEntranceID, "attach_to_entrance", "Link to entrance")
				.AddSource(&mEventID, "attach_to_event", "Link to post-leave event");

			ConditionLink_cl::Configure(sLinks, iParamA);
		}

		// Can Link / On Link / On Unlink: iParamA = VShapeLink *
		else
		{
			ConditionLink_cl::ManageLinkTo(this, iID, iParamA);

			ManageTypeLinkID(iID, iParamA, V_RUNTIME_CLASS(StageEntrance_cl), mEntranceID);
			ManageTypeLinkID(iID, iParamA, V_RUNTIME_CLASS(ChainEvent_cl), mEventID);
		}

		VisBaseEntity_cl::MessageFunction(iID, iParamA, iParamB);
	}
}

/// Serialization
void StageExit_cl::Serialize (VArchive & ar)
{
	const char VERSION = 6;

	char iReadVersion = BeginEntitySerialize(this, ar, VERSION);

	if (ar.IsLoading())
	{
		VASSERT_MSG(iReadVersion >= 4, "Obsolete exit version: please re-export");

		ar >> mEntranceID;
		ar >> mEventID;

		if (iReadVersion >= 5) ar >> RemoveOnDisable;
		if (iReadVersion >= 6) ar >> EnabledWhenZoneEntered;
	}

	else
	{
		/* VERSION 2 */
		ar << mEntranceID;

		/* VERSION 3 */
		ar << mEventID;

		/* VERSION 5 */
		ar << RemoveOnDisable;

		/* VERSION 6 */
		ar << EnabledWhenZoneEntered;
	}
}

///
void StageExit_cl::Leave (lua_State * L)
{
	if (mEventID)
	{
		// DO SOMETHING OR OTHER
	}

	if (mEntranceID)
	{
		VisBaseEntity_cl * pEntity = VisBaseEntity_cl::FindByUniqueID(mEntranceID); 

		VASSERT(pEntity && pEntity->IsOfType(V_RUNTIME_CLASS(StageEntrance_cl)));

		Game_cl::GetMe()->SetControlRawObjectProxy("entrance", pEntity);
	}

	Game_cl::GetMe()->SetControlBool("wants_to_exit", true);
}

/// Export validation
void StageExit_cl::Validate (INT_PTR iParam)
{
	// TODO: STUFF!
}

/* StageExit_cl variables */
V_IMPLEMENT_SERIAL( StageExit_cl, VisBaseEntity_cl /*parent class*/ , 0, &gGameModule );

START_VAR_TABLE(StageExit_cl, VisBaseEntity_cl, "", VVARIABLELIST_FLAGS_NONE, "Models/box_stage_exit.MODEL")

	DEFINE_VAR_BOOL(StageExit_cl, EnabledWhenZoneEntered, "Is exit enabled when you enter the zone?", "TRUE", 0, 0);
	DEFINE_VAR_BOOL(StageExit_cl, RemoveOnDisable, "Should the exit be permanently removed if it gets disabled?", "FALSE", 0, 0);

END_VAR_TABLE
--]]