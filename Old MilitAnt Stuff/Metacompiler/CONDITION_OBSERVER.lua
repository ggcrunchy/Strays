--- Condition observer from C++.

--[[
--
--
-- ConditionObserver.h
--
--
#ifndef _CONDITION_OBSERVER_CL
#define _CONDITION_OBSERVER_CL

// Forward references
struct lua_State;

class ActionLink_cl;

/// An entity that watches and responds to a condition
class ConditionObserver_cl : public VisBaseEntity_cl, IVisCallbackHandler_cl {
public:
	ConditionObserver_cl (void);

	VOVERRIDE void DeInitFunction (void);
	VOVERRIDE void InitFunction (void);
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);
	VOVERRIDE void OnDeserializationCallback (void * pUserData) { InitFunction(); }
	VOVERRIDE void OnHandleCallback (IVisCallbackDataObject_cl * pData);
	VOVERRIDE void ThinkFunction (void);

	VOVERRIDE VBool WantsDeserializationCallback (void) { return true; }

	V_DECLARE_SERIAL_DLLEXP(ConditionObserver_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(ConditionObserver_cl)

private:
	void ClearReferent (void);
	void Evaluate (lua_State * L, bool bTryToDisable = true);
	void ToggleThinking (void);
	void Validate (INT_PTR iParam);

	// vForge variables
	VString Expression;	///< Condition expression (cf. CompoundConditionNode_cl), as alternative to node link
	VString ReferentKey;///< Key of object using the condition, as alternative to object link
	BOOL DisableOnPass;	///< If true, the observer will be disabled after firing on a pass
	BOOL EvaluateRightAway;	///< If true, the first evaluation is made (and any response issued) as soon as the observer is enabled
	BOOL RemoveOnDisable;	///< If true, the observer should be removed from the scene if it becomes disabled
	BOOL ShouldMakeListing;	///< If true and possible, a code listing is generated for the condition
	BOOL StartOutThinking;	///< If true, the observer will start already thinking (ignored if a condition is bound)
	int Type;	///< Index for @b "condition_observers:referents" type

	// Implementation
	VSmartPtr<VisTriggerTargetComponent_cl> mDisable;	///< Target to disable this observer
	VSmartPtr<VisTriggerTargetComponent_cl> mEnable;///< Target to enable this observer
	VSmartPtr<VisTriggerTargetComponent_cl> mEvaluate;	///< Target to directly evaluate the condition; ignores @e DisableOnPass
	VSmartPtr<ActionLink_cl> mOnDisable;///< Link to @b On(Disable) actions
	VSmartPtr<ActionLink_cl> mOnEnable;	///< Link to @b On(Enable) actions
	VSmartPtr<ActionLink_cl> mOnPass;	///< Link to @b On(Pass) actions
	VSmartPtr<ConditionLink_cl> mIsFulfilled;	///< Link for condition: has the observed condition been fulfilled?
	VSmartPtr<ConditionLink_cl> mStartOutThinking;	///< Link for condition: should the observer start already thinking?
	VisTypedEngineObject_cl * mReferent;///< Cached referent object
	__int64 mObjectID;	///< Referent object to which observer is linked, if any
};

#endif
--]]

--[[
--
--
-- ConditionObserver.cpp
--
--
#include "stdafx.h"
#include "actionlink.h"
#include "conditionlink.h"
#include "conditionobserver.h"
#include "entitylinks.h"
#include "entityhelpers.h"
#include <vScript/VScriptManager.hpp>

/// Constructor
ConditionObserver_cl::ConditionObserver_cl (void) : mReferent(NULL), mObjectID(0)
{
}

/// Deinitialization
void ConditionObserver_cl::DeInitFunction (void)
{
	if (mReferent && mReferent != this) ClearReferent();

	VisBaseEntity_cl::DeInitFunction();
}

/// Initialization
void ConditionObserver_cl::InitFunction (void)
{
	VisBaseEntity_cl::InitFunction();

	if (!Vision::Editor.IsInEditor()) SetVisibleBitmask(0);
		
	SetThinkFunctionStatus(FALSE);

	static bool sRegistered;

	OnNewInstance(this, sRegistered);
}

/// Message handler
void ConditionObserver_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	static LinkComponentData sActions[] = {
		LINK_DATA_EX(ConditionObserver_cl, OnPass, "The condition passed", "Textures/Editor/co_onpass.dds"),
		LINK_DATA_EX(ConditionObserver_cl, OnDisable, "Observer got disabled", "Textures/Editor/e_ondisable.dds"),
		LINK_DATA_EX(ConditionObserver_cl, OnEnable, "Observer got enabled", "Textures/Editor/e_onenable.dds")
	};

	static LinkComponentData sLinks[] = {
		LINK_DATA_EX(ConditionObserver_cl, IsFulfilled, "Has the condition being observed been fulfilled?", NULL),
		LINK_DATA_EX(ConditionObserver_cl, StartOutThinking, "Should the observer start already thinking?", NULL)
	};

	static LinkComponentData sTargets[] = {
		LINK_DATA_EX(ConditionObserver_cl, Disable, "Disable the observer", "Textures/Editor/e_disable.dds"),
		LINK_DATA_EX(ConditionObserver_cl, Enable, "Enable the observer", "Textures/Editor/e_enable.dds"),
		LINK_DATA_EX(ConditionObserver_cl, Evaluate, "Manually evaluate the condition", "Textures/Editor/co_evaluate.dds")
	};

	lua_State * L = VScriptRM()->GetMasterState();

	// iParamA = VisTriggerSourceComponent_cl *, iParamB = VisTriggerTargetComponent_cl *
	if (VIS_MSG_TRIGGER == iID)
	{
		if (IsRemoved()) return;

		VisTriggerTargetComponent_cl * pTarget = (VisTriggerTargetComponent_cl *)iParamB;

		/* Enable or Disable */
		if ((GetThinkFunctionStatus() ? mDisable : mEnable) == pTarget)
		{
			ToggleThinking();

			// If requested, try a first evaluation when the observer is enabled.
			if (mEnable == pTarget && EvaluateRightAway) Evaluate(L);

			// If requested, remove the observer when it is disabled.
			else if (mDisable == pTarget && RemoveOnDisable) Remove();
		}

		/* Evaluate */
		else if (mEvaluate == pTarget) Evaluate(L, false);
	}

	// New Instance: iParamA = BOOL
	else if (ID_OBJECT_NEW_INSTANCE == iID)
	{
		SetupTriggerSources(this, sActions);
		SetupTriggerTargets(this, sTargets);

		ConditionLink_cl::SetupTargets(this, sLinks);

		mStartOutThinking->SetDefault(StartOutThinking != FALSE);

		// Try to bind a referent object, looking it up by ID or key, favoring the former;
		// if the lookup fails, the referent will be NULL. If neither lookup was requested,
		// the observer itself will be the referent.
		if (mObjectID) mReferent = VisBaseEntity_cl::FindByUniqueID(mObjectID);

		else if (!ReferentKey.IsEmpty()) mReferent = GetObjectByKey(GetEnumValue(this, "Type", Type), ReferentKey);

		else mReferent = this;

		// If an external object was successfully linked to the observer, plug into the "object
		// destroyed" callback, as the object may be removed while the observer remains active.
		if (mReferent && mReferent != this) VisObject3D_cl::OnObject3DDestroyed += this;

		/* First-time setup */
		if (iParamA) RegisterCollectionAndContext(L, V_RUNTIME_CLASS(ConditionObserver_cl), "condition_observers");
	}

	// Commit
	else if (ID_OBJECT_COMMIT == iID)
	{
		if (mStartOutThinking->Invoke()) ToggleThinking();
	}

	// Memory state archive: iParamA = VArchive *
	else if (ID_OBJECT_MEMORY_STATE_ARCHIVE == iID)
	{
		VArchive & ar = *(VArchive *)iParamA;

		if (ar.IsLoading())
		{
			BOOL bThinking;

			ar >> bThinking;

			// TODO: What now?
		}

		else
		{
			ar << GetThinkFunctionStatus();
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

			lb	.AddSource(&mObjectID, "attach_to_object", "Link to object");

			ConditionLink_cl::Configure(sLinks, iParamA);
		}

		// Can Link / On Link / On Unlink: iParamA = VShapeLink *
		else
		{
			ConditionLink_cl::ManageLinkTo(this, iID, iParamA);

			ManageTypeLinkID(iID, iParamA, V_RUNTIME_CLASS(VisBaseEntity_cl), mObjectID);
		}

		VisBaseEntity_cl::MessageFunction(iID, iParamA, iParamB);
	}
}

/// Callback handler
void ConditionObserver_cl::OnHandleCallback (IVisCallbackDataObject_cl * pData)
{
	VASSERT(&VisObject3D_cl::OnObject3DDestroyed == pData->m_pSender);

	if (mReferent == ((VisObject3DDataObject_cl *)pData)->m_pObject3D) ClearReferent();
}

/// Performs a regular evaluation
void ConditionObserver_cl::ThinkFunction (void)
{
	Evaluate(VScriptRM()->GetMasterState());
}

/// Serialization
void ConditionObserver_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = BeginEntitySerialize(this, ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Expression;
		ar >> ReferentKey;
		ar >> DisableOnPass;
		ar >> EvaluateRightAway;
		ar >> RemoveOnDisable;
		ar >> ShouldMakeListing;
		ar >> StartOutThinking;
		ar >> Type;
		ar >> mObjectID;
	}

	else
	{
		/* VERSION 1 */
		ar << Expression;
		ar << ReferentKey;
		ar << DisableOnPass;
		ar << EvaluateRightAway;
		ar << RemoveOnDisable;
		ar << ShouldMakeListing;
		ar << StartOutThinking;
		ar << Type;
		ar << mObjectID;
	}
}

/// Clears referent and associated state
void ConditionObserver_cl::ClearReferent (void)
{
	mReferent = NULL;

	VisObject3D_cl::OnObject3DDestroyed -= this;
}

/// Checks if the condition passes and if so invokes @e On(Pass) action
/// @param bTryToDisable If @b true, disable the observer if possible after a pass
void ConditionObserver_cl::Evaluate (lua_State * L, bool bTryToDisable)
{
	if (!mIsFulfilled->Invoke(Expression, mReferent)) return;

	mOnPass->Invoke();

	if (bTryToDisable && DisableOnPass) SendTriggerMessage(this, mDisable);
}

/// Toggles the observer from or to thinking state
void ConditionObserver_cl::ToggleThinking (void)
{
	BOOL bThinking = GetThinkFunctionStatus();

	(bThinking ? mOnDisable : mOnEnable)->Invoke();

	SetThinkFunctionStatus(!bThinking);
}

/// Export validation
void ConditionObserver_cl::Validate (INT_PTR iParam)
{
	// TODO: STUFF!
}

/// Referent types
static const char * Types = "ConvexVolume,Entity,LightSource,Path,StaticMeshInstance";

STATIC_ENUM_GROUP(ObserverEnums,
	{ "condition_observers:referents", Types }
);

/* ConditionObserver_cl variables */
V_IMPLEMENT_SERIAL( ConditionObserver_cl, VisBaseEntity_cl /*parent class*/ , 0, &gGameModule );

START_VAR_TABLE(ConditionObserver_cl, VisBaseEntity_cl, "", VVARIABLELIST_FLAGS_NONE, "Models/condition_observer.MODEL")

	DEFINE_VAR_VSTRING(ConditionObserver_cl, Expression, "Expression used to glue together condition components", "", 0, 0, 0);
	DEFINE_VAR_VSTRING(ConditionObserver_cl, ReferentKey, "Key for object used in evaluating the condition", "", 0, 0, 0);
	DEFINE_VAR_ENUM(ConditionObserver_cl, Type, "What type of object is referenced by the key?", "Entity", Types, 0, 0);

	/* On(Pass) */
	DEFINE_VAR_BOOL(ConditionObserver_cl, DisableOnPass, "Should the observer be disabled after the condition passes?", "TRUE", 0, 0);

	/* On(Enable) */
	DEFINE_VAR_BOOL(ConditionObserver_cl, EvaluateRightAway, "Should the observer try an evaluation as soon as enabled (versus waiting to think)?", "FALSE", 0, 0);

	/* On(Disable) */
	DEFINE_VAR_BOOL(ConditionObserver_cl, RemoveOnDisable, "Should the observer be permanently removed if it gets disabled?", "FALSE", 0, 0);

	/* Other */
	DEFINE_VAR_BOOL(ConditionObserver_cl, StartOutThinking, "Should the observer already be thinking once created?", "FALSE", 0, 0);
	DEFINE_VAR_BOOL(ConditionObserver_cl, ShouldMakeListing, "Should a code listing be made of the compiled condition?", "FALSE", 0, 0);

END_VAR_TABLE
--]]