--- Entrance from C++.

--[[
--
--
-- Entrance.h
--
--
#ifndef _ENTRANCE_CL
#define _ENTRANCE_CL

/// Forward references
class ActionLink_cl;
class NativeClassInfo;

/// An entrance point into a zone
class StageEntrance_cl : public VisBaseEntity_cl {
public:
	StageEntrance_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);
	VOVERRIDE void InitFunction (void);
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);
	VOVERRIDE void OnDeserializationCallback (void * pUserData) { InitFunction(); }
	VOVERRIDE void SetParentZone (VisZoneResource_cl * pNewZone);

	VOVERRIDE VBool WantsDeserializationCallback (void) { return true; }

	V_DECLARE_SERIAL_DLLEXP(StageEntrance_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(StageEntrance_cl)

private:
	void Alert (const StrComp & what, INT_PTR iParam);
	void Validate (INT_PTR iParam);

	static NativeClassInfo sNativeClassInfo;///< Info for class proxy

	// vForge variables
	BOOL InheritComponents;	///< If true, this entrance should inherit any missing entrance components from the prototype
	BOOL InheritEvent;	///< If true and the entrance has no event, this entrance should inherit any event from the prototype

	// Implementation
	VSmartPtr<ActionLink_cl> mOnEnter;	///< Link to @b On(Enter) actions
	VSmartPtr<ActionLink_cl> mOnSpawn;	///< Link to @b On(Spawn) actions
	__int64 mEventID;	///< Pre-enter event, if any
	__int64 mPrototypeID;	///< ID of prototype entrance to inherit common properties
	__int64 mReferentID;///< ID of reference object, if any
	__int64 mTriggerID;	///< ID of path follow trigger to which this entrance binds
	bool mIsPrototype;	///< If true, this entrance is being used as a prototype
};

#endif
--]]

--[[
--
--
-- Entrance.cpp
--
--
#include "stdafx.h"
#include "actionlink.h"
#include "entrance.h"
#include "chainevent.h"
#include "pathfollowtrigger.h"
#include "exit.h"
#include "cameracontroller.h"
#include "entitymanager.h"
#include "entitylinks.h"
#include "entityhelpers.h"
#include "game.h"
#include "player.h"
#include <vScript/VScriptManager.hpp>

/// Constructor
StageEntrance_cl::StageEntrance_cl (void) : mEventID(0), mPrototypeID(0), mReferentID(0), mTriggerID(0), mIsPrototype(false)
{
}

/// Hides properties when entrance is a prototype, or grays out invalid inheritances
void StageEntrance_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{
	if (mIsPrototype) info.m_bHidden = true;

	else if (EndsWith(pVar->GetName(), "Event") && mEventID) info.m_bReadOnly = true;
}

/// Initialization
void StageEntrance_cl::InitFunction (void)
{
	VisBaseEntity_cl::InitFunction();

#ifdef NDEBUG
	SetVisibleBitmask(VIS_ENTITY_INVISIBLE);
#endif

	static bool sRegistered;

	OnNewInstance(this, sRegistered);
}

/// Message handler
void StageEntrance_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	static LinkComponentData sActions[] = {
		LINK_DATA_EX(StageEntrance_cl, OnEnter, "Entered via entrance", "Textures/Editor/se_onenter.dds"),
		LINK_DATA_EX(StageEntrance_cl, OnSpawn, "Spawned into zone", "Textures/Editor/se_onspawn.dds")
	};

	lua_State * L = VScriptRM()->GetMasterState();

	// New Instance: iParamA = BOOL
	if (ID_OBJECT_NEW_INSTANCE == iID)
	{
		SetupTriggerSources(this, sActions);

		/* First-time setup */
		if (iParamA)
		{
			RegisterCollectionAndContext(L, V_RUNTIME_CLASS(StageEntrance_cl), "entrances", false);

			// Build a wrapper class for bindings.
			LUA_CreateWrapperClass(L, &sNativeClassInfo);
		}
	}

	// Alert: iParamA = const char * or NULL, iParamB = const void * or NULL
	else if (ID_OBJECT_ALERT == iID) Alert(iParamA, iParamB);

	// Validate export: iParamA = VisBeforeSceneExportedObject_cl *
	else if (ID_OBJECT_VALIDATE_EXPORT == iID) Validate(iParamA);

	// Other cases
	else
	{
		// Get Links: iParamA = VShapeLinkConfig *
		if (VIS_MSG_EDITOR_GETLINKS == iID)
		{
			LinkBuilder lb(iParamA);

			/* Targets */
			lb	.AddTarget(V_RUNTIME_CLASS(StageEntrance_cl), "use_prototype", "Link from entrance")
				.AddTarget(V_RUNTIME_CLASS(StageExit_cl), "use_entrance", "Link from exit");

			/* Sources */
			lb	.AddSource(&mEventID, "attach_to_event", "Link to pre-enter event")
				.AddSource(&mPrototypeID, "attach_to_prototype", "Link to prototype")
				.AddSource(&mReferentID, "attach_to_referent", "Link to referent")
				.AddSource(&mTriggerID, "attach_to_trigger", "Link to path follow trigger");
		}

		// Can Link / On Link / On Unlink: iParamA = VShapeLink *
		else
		{
			ManageTypeLink(iID, iParamA, V_RUNTIME_CLASS(StageEntrance_cl), &mIsPrototype);
			ManageTypeLink(iID, iParamA, V_RUNTIME_CLASS(StageExit_cl));
			ManageTypeLinkID(iID, iParamA, V_RUNTIME_CLASS(ChainEvent_cl), mEventID);
			ManageTypeLinkID(iID, iParamA, V_RUNTIME_CLASS(StageEntrance_cl), mPrototypeID);
			ManageTypeLinkID(iID, iParamA, V_RUNTIME_CLASS(VisBaseEntity_cl), mReferentID);
			ManageTypeLinkID(iID, iParamA, V_RUNTIME_CLASS(PathFollowTrigger_cl), mTriggerID);
		}

		VisBaseEntity_cl::MessageFunction(iID, iParamA, iParamB);
	}
}

/// Override that ignores attempts to set the zone, issuing a warning
void StageEntrance_cl::SetParentZone (VisZoneResource_cl * pNewZone)
{
	if (pNewZone != NULL) Vision::Error.Warning("Entrances must remain in the main layer");
}

/// Serialization
void StageEntrance_cl::Serialize (VArchive & ar)
{
	const char VERSION = 6;

	char iReadVersion = BeginEntitySerialize(this, ar, VERSION);

	if (ar.IsLoading())
	{
		VASSERT_MSG(iReadVersion >= 5, "Obsolete entrance version: please re-export");

		ar >> mReferentID;
		ar >> mTriggerID;
		ar >> mEventID;

		if (iReadVersion >= 6)
		{
			ar >> InheritComponents;
			ar >> InheritEvent;
			ar >> mPrototypeID;
		}
	}

	else
	{
		/* VERSION 2 */
		ar << mReferentID;

		/* VERSION 3 */
		ar << mTriggerID;

		/* VERSION 4 */
		ar << mEventID;

		/* VERSION 6 */
		ar << InheritComponents;
		ar << InheritEvent;
		ar << mPrototypeID;
	}
}

///
/// @param what
/// @param iParam
void StageEntrance_cl::Alert (const StrComp & what, INT_PTR iParam)
{
	/* Enter: iParam = lua_State * */
	if (what == "enter")
	{
		// Look up the last check point crossed. If one has not yet been crossed, choose
		// the trigger associated with the entrance.
		__int64 id = PathFollowTrigger_cl::GetLastCheckpointID();

		if (!id)
		{
			id = mTriggerID;

			VASSERT(id);

			// When just entering the zone, do setup and invoke any 'On(Enter)' action.
			Game_cl::GetMe()->FireControlDelegate("on_entering_zone");

			mOnEnter->Invoke();

			// DO SOMETHING OR OTHER
			if (mEventID)
			{
			}
		}

		// Move the players (reviving them if dead) and camera to the trigger position.
		// The players will trip the check point in doing so, if it was not the last.
		PathFollowTrigger_cl * pTrigger = (PathFollowTrigger_cl *)VisBaseEntity_cl::FindByUniqueID(id);

		VASSERT(pTrigger);
		VASSERT(pTrigger->IsCheckpoint());

		VisVector_cl pos = pTrigger->GetPosition();

		for (unsigned i = 0; i < Game_cl::GetMe()->GetNumberOfPlayers(); ++i)
		{
			Player_cl * pPlayer = Game_cl::GetMe()->GetPlayer(i);

			if (pPlayer)
			{
				pPlayer->Revive();
				pPlayer->GoToPosition(pos);
			}
		}

		CameraController_cl::GetMe()->GoToPosition(pos);
	}

	/* Spawn: iParam = lua_State * */
	else if (what == "spawn") mOnSpawn->Invoke();
}

/// Export validation
void StageEntrance_cl::Validate (INT_PTR iParam)
{
	VisBaseEntity_cl * pTrigger = mTriggerID ? VisBaseEntity_cl::FindByUniqueID(mTriggerID) : NULL;

	if (!pTrigger || !pTrigger->IsOfType(V_RUNTIME_CLASS(PathFollowTrigger_cl))) FailValidation(iParam, "Entrance not linked to path follow trigger");

	else if (!((PathFollowTrigger_cl *)pTrigger)->IsCheckpoint()) FailValidation(iParam, "Entrance trigger must be a check point");
}

/* Bindings */

///
static int EnterB (lua_State * L)
{
	DECLARE_ARGS_OK;
	GET_OBJECT(StageEntrance_cl *, se);

	SendAlert(se, "enter", L);

	return 0;
}

///
static int PreEnterB (lua_State * L)
{
	DECLARE_ARGS_OK;
	GET_OBJECT(StageEntrance_cl *, se);

	// Choose the zone, given the entrance position.
	VisVector_cl pos = se->GetPosition();

	VisZoneResource_cl * pZone = NULL;

	for (int i = 0; i < VisZoneResourceManager_cl::GlobalManager().GetResourceCount(); ++i)
	{
		pZone = VisZoneResourceManager_cl::GlobalManager().GetZoneByIndex(i);

		if (pZone && pZone->m_BoundingBox.IsInside(pos)) break;
	}

	VASSERT_MSG(pZone, "Entrance is outside of any zone");

	// Load the zone.
	Game_cl::GetMe()->PrepareZone(pZone);

	return 0;
}

///
static int SpawnB (lua_State * L)
{
	DECLARE_ARGS_OK;
	GET_OBJECT(StageEntrance_cl *, se);

	SendAlert(se, "spawn", L);

	return 0;
}

/* StageEntrance_cl proxy methods */
static const luaL_Reg sMethods[] = 
{
	{ "Enter", EnterB },
	{ "PreEnter", PreEnterB },
	{ "Spawn", SpawnB },
	{ 0, 0 }
};

NativeClassInfo StageEntrance_cl::sNativeClassInfo =
{
	"StageEntrance_cl", &VisBaseEntity_info, sMethods
};

/* StageEntrance_cl variables */
V_IMPLEMENT_SERIAL( StageEntrance_cl, VisBaseEntity_cl /*parent class*/ , 0, &gGameModule );

START_VAR_TABLE(StageEntrance_cl, VisBaseEntity_cl, "", VVARIABLELIST_FLAGS_NONE, "Models/box_stage_entrance.MODEL")

	DEFINE_VAR_BOOL(StageEntrance_cl, InheritComponents, "If missing, inherit entrance components from the prototype?", "TRUE", 0, 0);
	DEFINE_VAR_BOOL(StageEntrance_cl, InheritEvent, "If missing, inherit event from the prototype?", "TRUE", 0, 0);

END_VAR_TABLE
--]]