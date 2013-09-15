--- Scroll barrier from C++.

--[[
--
--
-- ScrollBarrier.h
--
--
#ifndef _SCROLL_BARRIER_CL
#define _SCROLL_BARRIER_CL

// Forward references
class ActionLink_cl;
class vPhysXRigidBody;

/// An entity used to restrict camera and player movement
class ScrollBarrier_cl : public VisBaseEntity_cl {
public:
	ScrollBarrier_cl (void);

	VOVERRIDE void InitFunction (void);
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);
	VOVERRIDE void OnDeserializationCallback (void * pUserData) { InitFunction(); }

	VOVERRIDE VBool WantsDeserializationCallback (void) { return true; }

	V_DECLARE_SERIAL_DLLEXP(ScrollBarrier_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(ScrollBarrier_cl)

private:
	void Validate (INT_PTR iParam);

	// vForge variables

	// Implementation
	VSmartPtr<VisTriggerTargetComponent_cl> mAddOneLock;///< Target to add another scroll lock
	VSmartPtr<VisTriggerTargetComponent_cl> mRemoveOneLock;	///< Target to remove a scroll lock
	VSmartPtr<ActionLink_cl> mOnLock;	///< Link to @b On(Lock) actions
	VSmartPtr<ActionLink_cl> mOnUnlock;	///< Link to @b On(Unlock) actions
	int mLockCount;	///< Number of removes left before unlock
};

#endif
--]]

--[[
--
--
-- ScrollBarrier.cpp
--
--
#include "stdafx.h"
#include "actionlink.h"
#include "scrollbarrier.h"
#include "entitylinks.h"
#include "entityhelpers.h"
#include "Game.h"
#include <vScript/VScriptManager.hpp>

/// Constructor
ScrollBarrier_cl::ScrollBarrier_cl (void) : mLockCount(0)
{
}

/// Initialization
void ScrollBarrier_cl::InitFunction (void)
{
	VisBaseEntity_cl::InitFunction();

	if (!Vision::Editor.IsInEditor()) SetVisibleBitmask(0);

	static bool sRegistered;

	OnNewInstance(this, sRegistered);
}

/// Message handler
void ScrollBarrier_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	static LinkComponentData sActions[] = {
		LINK_DATA_EX(ScrollBarrier_cl, OnLock, "Barrier got locked", "Textures/Editor/sb_onlock.dds"),
		LINK_DATA_EX(ScrollBarrier_cl, OnUnlock, "Barrier got unlocked", "Textures/Editor/sb_onunlock.dds")
	};

	static LinkComponentData sTargets[] = {
		LINK_DATA_EX(ScrollBarrier_cl, AddOneLock, "Add a lock to the barrier", "Textures/Editor/sb_addonelock.dds"),
		LINK_DATA_EX(ScrollBarrier_cl, RemoveOneLock, "Remove a lock from the barrier", "Textures/Editor/sb_removeonelock.dds")
	};

	lua_State * L = VScriptRM()->GetMasterState();

	// iParamA = VisTriggerSourceComponent_cl *, iParamB = VisTriggerTargetComponent_cl *
	if (VIS_MSG_TRIGGER == iID)
	{
		VisTriggerTargetComponent_cl * pTarget = (VisTriggerTargetComponent_cl *)iParamB;

		/* Add one lock */
		if (mAddOneLock == pTarget && mLockCount++ == 0) mOnLock->Invoke();

		/* Remove one lock */
		else if (mRemoveOneLock == pTarget && DecrementOnTrigger(this, mLockCount, "resume unlocked scroll barrier")) mOnUnlock->Invoke();
	}

	// New Instance: iParamA = BOOL
	else if (ID_OBJECT_NEW_INSTANCE == iID)
	{
		SetupTriggerSources(this, sActions);
		SetupTriggerTargets(this, sTargets);

		/* First-time setup */
		if (iParamA) RegisterCollectionAndContext(L, V_RUNTIME_CLASS(ScrollBarrier_cl), "scroll_barriers");
	}

	// Alert: iParamA = const char * or NULL, iParamB = const void * or NULL
	else if (ID_OBJECT_ALERT == iID && StrComp(iParamA) == "follow_up:action")
	{
		const ActionLink_cl * pInvokee = ((ActionLink_cl::FollowUpArgs *)iParamB)->mInvokee;

		if (mOnLock == pInvokee) Game_cl::GetMe()->EnterWaveEncounter(this);

		else if (mOnUnlock == pInvokee) Game_cl::GetMe()->LeaveWaveEncounter(this);
	}

	// Other cases
	else VisBaseEntity_cl::MessageFunction(iID, iParamA, iParamB);
}

/// Serialization
void ScrollBarrier_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = BeginEntitySerialize(this, ar, VERSION);
}

/// Export validation
void ScrollBarrier_cl::Validate (INT_PTR iParam)
{
	int acount = CountComponents(mAddOneLock->m_Sources);
	int rcount = CountComponents(mRemoveOneLock->m_Sources);

	if (acount != rcount) FailValidation(iParam, "Unbalanced lock pair: number of adds %s number of removes", acount < rcount ? "<" : ">");
}

/* ScrollBarrier_cl variables */
V_IMPLEMENT_SERIAL( ScrollBarrier_cl, VisBaseEntity_cl /*parent class*/ , 0, &gGameModule );

START_VAR_TABLE(ScrollBarrier_cl, VisBaseEntity_cl, "", VVARIABLELIST_FLAGS_NONE, "Models/box_empty_model.MODEL")

END_VAR_TABLE
--]]