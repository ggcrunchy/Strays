--- Condition components from C++.

--[[
--
--
-- ConditionComponents.h
--
--
#ifndef _CONDITION_COMPONENT_CL
#define _CONDITION_COMPONENT_CL

#include "entityvars.h"

/// Base for components that provide a condition
class ConditionComponent_cl : public IVObjectComponent {
public:
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);

	VOVERRIDE BOOL CanAttachToObject (VisTypedEngineObject_cl * pObject, VString & sErrorMsgOut);

	V_DECLARE_DYNAMIC(ConditionComponent_cl)
	IMPLEMENT_OBJ_CLASS(ConditionComponent_cl)

	bool MatchesLabel (const char * label) const { return Label == label; }

protected:
	char CommonSerialize (VArchive & ar, char iLocalVersion);

	virtual void Push (lua_State * L) = 0;

	virtual bool ValidateExport (VString & sErrorMsgOut) { return true; }

	// vForge variables
	VString Label;	///< Label used to inject component as clause in expressions

	// Implementation
};

/// Component for a condition evaluated from the result of an alert
class Alert_ConditionComponent_cl : public ConditionComponent_cl, private AlertVar {
public:
	Alert_ConditionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);

	V_DECLARE_SERIAL_DLLEXP(Alert_ConditionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(Alert_ConditionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	BOOL Negate;///< If true, result is negated
};

/// Component for a condition evaluated from a boolean
class Bool_ConditionComponent_cl : public ConditionComponent_cl, private BaseVar {
public:
	Bool_ConditionComponent_cl (void);

	V_DECLARE_SERIAL_DLLEXP(Bool_ConditionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(Bool_ConditionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	int Op;	///< Index for @b "conditions:bool" operation
};

/// Component for a condition evaluated from the result of a function
class Call_ConditionComponent_cl : public ConditionComponent_cl, private CallVar {
public:
	Call_ConditionComponent_cl (void);

	V_DECLARE_SERIAL_DLLEXP(Call_ConditionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(Call_ConditionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	BOOL Negate;///< If true, result is negated
};

/// Component for a condition that compares two numbers
class CompareNums_ConditionComponent_cl : public ConditionComponent_cl {
public:
	CompareNums_ConditionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(CompareNums_ConditionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(CompareNums_ConditionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	NumVar Num1;///< Number #1 info
	NumVar Num2;///< Number #2 info
	int Op;	///< Index for @b "conditions:compare_nums" operation
};

/*
	Date / Time components???
*/

/// Component for a condition that checks whether an interval contains a number
class IntervalContainsNum_ConditionComponent_cl : public ConditionComponent_cl, private NumVar {
public:
	IntervalContainsNum_ConditionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(IntervalContainsNum_ConditionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(IntervalContainsNum_ConditionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	NumVar Left;///< Left side of the interval's info
	NumVar Right;	///< Right side of the interval's info
	BOOL OpenOnLeft;///< If true, the interval is open on the left, i.e. @e Left < @e Num; otherwise, @e Left <= @e Num
	BOOL OpenOnRight;	///< If true, the interval is open on the right, i.e. @e Num < @e Right; otherwise, @e Num <= @e Right
};

/// Component for a condition that evaluates two objects' proximity
class Proximity_ConditionComponent_cl : public ConditionComponent_cl {
public:
	Proximity_ConditionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(Proximity_ConditionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(Proximity_ConditionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	NumVar Distance;///< Reference distance used to evaluate proximity
	NumVar Distance2;	///< Reference distance #2, for certain operations
	VString EntityType;	///< Optional sub-type for filtering, if @e Type specifies entities
	VString OtherObjectKey;	///< Key of object being compared for proximity
	int Op;	///< Index for @b "conditions:proximity" operation
	int Type;	///< Index for "object_key_type" type
};

/// Component for a condition that evaluates the state of a timer variable
class Timer_ConditionComponent_cl : public ConditionComponent_cl, private BaseVar {
public:
	Timer_ConditionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(Timer_ConditionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(Timer_ConditionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	BOOL AbsenceAsFailure;	///< If true, non-existence of the variable means failure, except in @b "Exists" op; ignores @e Negate
	BOOL Negate;///< If true, result is negated
	int Op;	///< Index for @b "conditions:timer" operation
};

#endif
--]]

--[[
--
--
-- ConditionComponents.cpp
--
--
#include "stdafx.h"
#include "conditioncomponents.h"
#include "conditionlink.h"
#include "actionnode.h"
#include "conditionnode.h"
#include "entityhelpers.h"
#include <vScript/VScriptManager.hpp>

/// Message handler
void ConditionComponent_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	// Alert: iParamA = const char * or NULL, iParamB = const void * or NULL
	if (ID_OBJECT_ALERT == iID && StrComp(iParamA) == "push") Push(VScriptRM()->GetMasterState());

	// Other cases
	else IVObjectComponent::MessageFunction(iID, iParamA, iParamB);
}

///
BOOL ConditionComponent_cl::CanAttachToObject (VisTypedEngineObject_cl * object, VString & sErrorMsgOut)
{
	if (!IVObjectComponent::CanAttachToObject(object, sErrorMsgOut)) return FALSE;

	//
	if (object->IsOfType(V_RUNTIME_CLASS(ConditionNodeBase_cl))) return TRUE;
	if (object->IsOfType(V_RUNTIME_CLASS(ActionNode_cl))) return TRUE;
	if (CountComponents(object, V_RUNTIME_CLASS(ConditionLink_cl)) > 0) return TRUE;

	sErrorMsgOut = "Component can only be assigned to a condition node, action node, or an object with condition links.";

	return FALSE;
}

///
char ConditionComponent_cl::CommonSerialize (VArchive & ar, char iLocalVersion)
{
	char iReadVersion = BeginComponentSerialize(this, ar, iLocalVersion);

	if (ar.IsLoading())
	{
		ar >> Label;
	}

	else
	{
		/* VERSION 1 */
		ar << Label;
	}

	return iReadVersion;
}

/* ConditionComponent_cl variables */
V_IMPLEMENT_DYNAMIC(ConditionComponent_cl, IVObjectComponent, Vision::GetEngineModule());

START_VAR_TABLE(ConditionComponent_cl, IVObjectComponent, "", VFORGE_HIDECLASS, "defaultBox")

	DEFINE_VAR_VSTRING(ConditionComponent_cl, Label, "If free, what is this component's label?", "", 0, 0, NULL);

END_VAR_TABLE
--]]

--[[
--
--
-- ConditionComponents_Alert.cpp
--
--
#include "stdafx.h"
#include "conditioncomponents.h"
#include "entitymanager.h"
#include "Lua_/Lua.h"

/// Constructor
Alert_ConditionComponent_cl::Alert_ConditionComponent_cl (void)
{
	Initialize();
}

///
void Alert_ConditionComponent_cl::Push (lua_State * L)
{
	if (Named) ResolveName(GetOwner());

	PUSH_STATIC_PRIVATE_VAR(AlertVar);	// ..., avar

	lua_pushboolean(L, Negate != FALSE);// ..., avar, negate
}

///
void Alert_ConditionComponent_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{
	GetAttributes(pVar, info);
}

/// Message handler
void Alert_ConditionComponent_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	// Get Standard Values: iParamA = "condition_alerts", iParamB = VStrList *
	if (VIS_MSG_EDITOR_GETSTANDARDVALUES == iID && StrComp(iParamA) == "global_alerts") SendMsg(GlobalReceiver_cl::GetMe(), iID, INT_PTR("enum_alerts:condition"), iParamB);

	// Other cases
	else ConditionComponent_cl::MessageFunction(iID, iParamA, iParamB);
}

/// Serialization
void Alert_ConditionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Negate;
	}

	else
	{
		/* VERSION 1 */
		ar << Negate;
	}

	/* VERSION 1 */
	AlertVar::Begin(ar);
	AlertVar::Serialize(ar);
}

/* Alert_ConditionComponent_cl variables */
V_IMPLEMENT_SERIAL(Alert_ConditionComponent_cl, ConditionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(Alert_ConditionComponent_cl, ConditionComponent_cl, "Condition that reacts to an alert sent to the referent", VCOMPONENT_ALLOW_MULTIPLE, "'Alert' Condition")

	DEFINE_ALERTVAR_DERIVED(Alert_ConditionComponent_cl);
	DEFINE_VAR_BOOL(Alert_ConditionComponent_cl, Negate, "Treat a false result as success?", "FALSE", 0, 0);

END_VAR_TABLE
--]]

--[[
--
--
-- ConditionComponents_Bool.cpp
--
--
#include "stdafx.h"
#include "conditioncomponents.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// Constructor
Bool_ConditionComponent_cl::Bool_ConditionComponent_cl (void)
{
	Initialize();
}

///
void Bool_ConditionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(BaseVar);	// ..., bvar

	lua_pushstring(L, GetEnumValue(this, "Op", Op));// ..., bvar, op
}

/// Serialization
void Bool_ConditionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Op;
	}

	else
	{
		/* VERSION 1 */
		ar << Op;
	}

	/* VERSION 1 */
	BaseVar::Begin(ar);
	BaseVar::Serialize(ar);
}

/// Boolean condition operations
static const char * Ops = "IsTrue,IsFalse";

STATIC_ENUM_GROUP(ConditionEnums,
	{ "conditions:bool", Ops }
);

/* Bool_ConditionComponent_cl variables */
V_IMPLEMENT_SERIAL(Bool_ConditionComponent_cl, ConditionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(Bool_ConditionComponent_cl, ConditionComponent_cl, "Condition that evaluates a boolean", VCOMPONENT_ALLOW_MULTIPLE, "'Boolean' Condition")

	DEFINE_BASEVAR_DERIVED(Bool_ConditionComponent_cl, "Zone", "boolean", BaseVar::sFamilyEx);
	DEFINE_VAR_ENUM(Bool_ConditionComponent_cl, Op, "Operation used to test bool", "IsTrue", Ops, 0, 0);

END_VAR_TABLE
--]]

--[[
--
--
-- ConditionComponents_Call.cpp
--
--
#include "stdafx.h"
#include "conditioncomponents.h"
#include "Lua_/Lua.h"

/// Constructor
Call_ConditionComponent_cl::Call_ConditionComponent_cl (void)
{
	Initialize();
}

///
void Call_ConditionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(CallVar);	// ..., cvar

	lua_pushboolean(L, Negate != FALSE);// ..., cvar, negate
}

/// Serialization
void Call_ConditionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Negate;
	}

	else
	{
		/* VERSION 1 */
		ar << Negate;
	}

	/* VERSION 1 */
	CallVar::Begin(ar);
	CallVar::Serialize(ar);
}

/* Call_ConditionComponent_cl variables */
V_IMPLEMENT_SERIAL(Call_ConditionComponent_cl, ConditionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(Call_ConditionComponent_cl, ConditionComponent_cl, "Condition that calls another function (if missing, fails)", VCOMPONENT_ALLOW_MULTIPLE, "'Call' Condition")

	DEFINE_CALLVAR_DERIVED(Call_ConditionComponent_cl, "Zone");
	DEFINE_VAR_BOOL(Call_ConditionComponent_cl, Negate, "Treat a false result as success?", "FALSE", 0, 0);

END_VAR_TABLE
--]]

--[[
--
--
-- ConditionComponents_CompareNums.cpp
--
--
#include "stdafx.h"
#include "conditioncomponents.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// Constructor
CompareNums_ConditionComponent_cl::CompareNums_ConditionComponent_cl (void)
{
	Initialize();
}

///
void CompareNums_ConditionComponent_cl::Push (lua_State * L)
{
	lua_pushlightuserdata(L, &Num1);// ..., nvar1
	lua_pushlightuserdata(L, &Num2);// ..., nvar1, nvar2
	lua_pushstring(L, GetEnumValue(this, "Op", Op));// ..., nvar1, nvar2, op
}

///
void CompareNums_ConditionComponent_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{
	StrComp name(pVar);

	if (name == "Label" || name == "Op") return;

	NumVar & num = VStringHelper::StartsWith(name, "Num1.") ? Num1 : Num2;

	num.GetAttributes(name, info);
}

/// Serialization
void CompareNums_ConditionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Op;
	}

	else
	{
		/* VERSION 1 */
		ar << Op;
	}

	/* SELF-VERSIONED */
	NumVar::Begin(ar);

	Num1.Serialize(ar);
	Num2.Serialize(ar);
}

/// Number condition operations
static const char * Ops = "==,~=,<,<=,>,>=";

STATIC_ENUM_GROUP(ConditionEnums,
	{ "conditions:compare_nums", Ops }
)

/* CompareNums_ConditionComponent_cl variables */
V_IMPLEMENT_SERIAL(CompareNums_ConditionComponent_cl, ConditionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(CompareNums_ConditionComponent_cl, ConditionComponent_cl, "Condition that compares two numbers", VCOMPONENT_ALLOW_MULTIPLE, "'Compare numbers' Condition")

	DEFINE_NUMVAR_MEMBER(CompareNums_ConditionComponent_cl, Num1, "Zone", "Variable", BaseVar::sFamilyEx);
	DEFINE_NUMVAR_MEMBER(CompareNums_ConditionComponent_cl, Num2, "Zone", "Constant", BaseVar::sFamilyEx);
	DEFINE_VAR_ENUM(CompareNums_ConditionComponent_cl, Op, "Operation used to compare numbers, i.e. Num1 op Num2", "==", Ops, 0, 0);

END_VAR_TABLE
--]]

--[[
--
--
-- ConditionComponents_ContainsNum.cpp
--
--
#include "stdafx.h"
#include "conditioncomponents.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// Constructor
IntervalContainsNum_ConditionComponent_cl::IntervalContainsNum_ConditionComponent_cl (void)
{
	Initialize();
}

///
void IntervalContainsNum_ConditionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(NumVar);// ..., nvar

	lua_pushlightuserdata(L, &Left);// ..., nvar, left
	lua_pushlightuserdata(L, &Right);	// ..., nvar, left, right
	lua_pushboolean(L, OpenOnLeft != FALSE);// ..., nvar, left, right, open_on_left
	lua_pushboolean(L, OpenOnRight != FALSE);	// ..., nvar, left, right, open_on_left, open_on_right
}

///
void IntervalContainsNum_ConditionComponent_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{
	StrComp name(pVar);

	if (name == "Label" || VStringHelper::StartsWith(name, "OpenOn")) return;
	else if (VStringHelper::StartsWith(name, "Left.")) Left.GetAttributes(name, info);
	else if (VStringHelper::StartsWith(name, "Right.")) Right.GetAttributes(name, info);
	else GetAttributes(name, info);
}

/// Serialization
void IntervalContainsNum_ConditionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> OpenOnLeft;
		ar >> OpenOnRight;
	}

	else
	{
		/* VERSION 1 */
		ar << OpenOnLeft;
		ar << OpenOnRight;
	}

	/* SELF-VERSIONED */
	NumVar::Begin(ar);

	NumVar::Serialize(ar);
	Left.Serialize(ar);
	Right.Serialize(ar);
}

/* IntervalContainsNum_ConditionComponent_cl variables */
V_IMPLEMENT_SERIAL(IntervalContainsNum_ConditionComponent_cl, ConditionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(IntervalContainsNum_ConditionComponent_cl, ConditionComponent_cl, "Condition that checks whether a number is contained in an interval", VCOMPONENT_ALLOW_MULTIPLE, "'Number contained in interval' Condition")

	DEFINE_NUMVAR_DERIVED(IntervalContainsNum_ConditionComponent_cl, "Zone", "Variable", BaseVar::sFamilyEx);
	DEFINE_NUMVAR_MEMBER(IntervalContainsNum_ConditionComponent_cl, Left, "Zone", "Constant", BaseVar::sFamilyEx);
	DEFINE_NUMVAR_MEMBER(IntervalContainsNum_ConditionComponent_cl, Right, "Zone", "Constant", BaseVar::sFamilyEx);
	DEFINE_VAR_BOOL(IntervalContainsNum_ConditionComponent_cl, OpenOnLeft, "If true, check Left < number; otherwise, check Left <= number", "FALSE", 0, 0);
	DEFINE_VAR_BOOL(IntervalContainsNum_ConditionComponent_cl, OpenOnRight, "If true, check number < Right; otherwise, number <= Right", "FALSE", 0, 0);

END_VAR_TABLE
--]]

--[[
--
--
-- ConditionComponents_Timer.cpp
--
--
#include "stdafx.h"
#include "conditioncomponents.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// Constructor
Timer_ConditionComponent_cl::Timer_ConditionComponent_cl (void)
{
	Initialize();
}

///
void Timer_ConditionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(BaseVar);	// ..., bvar

	lua_pushstring(L, GetEnumValue(this, "Op", Op));// ..., bvar, op
	lua_pushboolean(L, AbsenceAsFailure != FALSE);	// ..., bvar, op, absence_as_failure
	lua_pushboolean(L, Negate != FALSE);// ..., bvar, op, absence_as_failure, negate
}

///
void Timer_ConditionComponent_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{
	// Hide the absence-as-failure flag when using the "Exists" op.
	if (StrComp(pVar) == "AbsenceAsFailure") info.m_bHidden = GetEnumValue(this, "Op", Op) == "Exists";
}

/// Serialization
void Timer_ConditionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Op;
		ar >> AbsenceAsFailure;
		ar >> Negate;
	}

	else
	{
		/* VERSION 1 */
		ar << Op;
		ar << AbsenceAsFailure;
		ar << Negate;
	}

	/* VERSION 1 */
	BaseVar::Begin(ar);
	BaseVar::Serialize(ar);
}

/// Timer condition operations
static const char * Ops = "Exists,Running,Paused,Done,Elapsed";

STATIC_ENUM_GROUP(ConditionEnums,
	{ "conditions:timer", Ops }
);

/* Timer_ConditionComponent_cl variables */
V_IMPLEMENT_SERIAL(Timer_ConditionComponent_cl, ConditionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(Timer_ConditionComponent_cl, ConditionComponent_cl, "Condition that evaluates a timer variable", VCOMPONENT_ALLOW_MULTIPLE, "'Timer variable' Condition")

	DEFINE_BASEVAR_DERIVED(Timer_ConditionComponent_cl, "Zone", "timer", BaseVar::sFamily);
	DEFINE_VAR_ENUM(Timer_ConditionComponent_cl, Op, "Operation used to test timer", "Exists", Ops, 0, 0);
	DEFINE_VAR_BOOL(Timer_ConditionComponent_cl, AbsenceAsFailure, "Is the operation always a failure if the timer does not exist?", "FALSE", 0, 0);
	DEFINE_VAR_BOOL(Timer_ConditionComponent_cl, Negate, "Treat a false result as success?", "FALSE", 0, 0);

END_VAR_TABLE
--]]