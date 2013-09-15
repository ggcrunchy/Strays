--- Action components from C++.

--[[
--
--
-- ActionComponents.h
--
--
#ifndef _ACTION_COMPONENT_CL
#define _ACTION_COMPONENT_CL

#include "entityvars.h"

// Forward references
class CompoundConditionNode_cl;

/// Base for components that provide an action op
class ActionComponent_cl : public IVObjectComponent {
public:
	VOVERRIDE BOOL CanAttachToObject (VisTypedEngineObject_cl * pObject, VString & sErrorMsgOut);

	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);

	V_DECLARE_DYNAMIC(ActionComponent_cl)
	IMPLEMENT_OBJ_CLASS(ActionComponent_cl)

protected:
	char CommonSerialize (VArchive & ar, char iLocalVersion);

	virtual void Push (lua_State * L) = 0;

	virtual bool ValidateExport (VString & sErrorMsgOut) { return true; }
};

/// Component for an op that sends an alert during an action
class Alert_ActionComponent_cl : public ActionComponent_cl, private AlertVar {
public:
	Alert_ActionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);

	V_DECLARE_SERIAL_DLLEXP(Alert_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(Alert_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);
};

/// Component for an op that arithmetically mutates a number during an action
class ArithmeticMutateNum_ActionComponent_cl : public ActionComponent_cl, private BaseVar {
public:
	ArithmeticMutateNum_ActionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(ArithmeticMutateNum_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(ArithmeticMutateNum_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	NumVar Num2;///< Second number in operation
	int Op;	///< Index for @b "actions:arithmetic_mutate" operation
};

/// Component for an op that assigns a boolean op during an action
class AssignBool_ActionComponent_cl : public ActionComponent_cl, private BaseVar {
public:
	AssignBool_ActionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(AssignBool_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(AssignBool_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	VString Expression;	///< Condition expression (cf. CompoundConditionNode_cl)
	VString ReferentKey;///< Key of object using the condition
	int Op;	///< Index for @b "actions:assign_bool" operation
	int Type;	///< Index for @b "actions:bool_referents" type

	// Implementation
	CompoundConditionNode_cl * mNode;	///<
	VisTypedEngineObject_cl * mReferent;///< Cached referent object
};

/// Component for an op that assigns a number during an action
class AssignNum_ActionComponent_cl : public ActionComponent_cl, private NumVar {
public:
	AssignNum_ActionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(AssignNum_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(AssignNum_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);
};

/// Component for an op that sends alerts to multiple external objects during an action
class BroadcastAlert_ActionComponent_cl : public ActionComponent_cl, private BroadcastVar, AlertVar {
public:
	BroadcastAlert_ActionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(BroadcastAlert_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(BroadcastAlert_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// Implementation
	CompoundConditionNode_cl * mNode;	///<
	VType * mType;	///<
};

/// Component for an op that calls with multiple external objects during an action
class BroadcastCall_ActionComponent_cl : public ActionComponent_cl, private BroadcastVar, CallVar {
public:
	BroadcastCall_ActionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(BroadcastAlert_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(BroadcastCall_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// Implementation
	CompoundConditionNode_cl * mNode;	///<
	VType * mType;	///<
};

/// Component for an op that makes a call during an action
class Call_ActionComponent_cl : public ActionComponent_cl, private CallVar {
public:
	Call_ActionComponent_cl (void);

	V_DECLARE_SERIAL_DLLEXP(Call_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(Call_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);
};

/// Component for an op that copies a variable during an action
class Copy_ActionComponent_cl : public ActionComponent_cl {
public:
	Copy_ActionComponent_cl (void);

	V_DECLARE_SERIAL_DLLEXP(Copy_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(Copy_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	BaseVar From;	///< Source variable
	BaseVar To;	///< Target variable
	int Type;	///< Type to which the variables belong
};

/// Component for an op to emit a variable to output
class OutputVar_ActionComponent_cl : public ActionComponent_cl, private BaseVar {
public:
	OutputVar_ActionComponent_cl (void);

	V_DECLARE_SERIAL_DLLEXP(OutputVar_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(OutputVar_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	int Op;	///< Index for @b "actions:output_var" operation
	int Type;	///< Type to which the variable belongs
};

/// Component for an op that applies a simple number mutate during an action
class SimpleMutateNum_ActionComponent_cl : public ActionComponent_cl, private BaseVar {
public:
	SimpleMutateNum_ActionComponent_cl (void);

	V_DECLARE_SERIAL_DLLEXP(SimpleMutateNum_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(SimpleMutateNum_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	int Op;	///< Index for @b "actions:simple_mutate" operation
};

/// Component for an op that involves a timer during an action
class Timer_ActionComponent_cl : public ActionComponent_cl, private BaseVar {
public:
	Timer_ActionComponent_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);

	V_DECLARE_SERIAL_DLLEXP(Timer_ActionComponent_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(Timer_ActionComponent_cl)

private:
	virtual void Push (lua_State * L);

	// vForge variables
	NumVar Duration;///< Timer duration, for start operation
	int Op;	///< Index for @b "actions:timer" operation
};

#endif
--]]

--[[
--
--
-- ActionComponents.cpp
--
--
#include "stdafx.h"
#include "actioncomponents.h"
#include "actionnode.h"
#include "entityhelpers.h"
#include <vScript/VScriptManager.hpp>

///
BOOL ActionComponent_cl::CanAttachToObject (VisTypedEngineObject_cl * object, VString & sErrorMsgOut)
{
	if (!IVObjectComponent::CanAttachToObject(object, sErrorMsgOut)) return FALSE;

	//
	if (!object->IsOfType(V_RUNTIME_CLASS(ActionNode_cl)))
	{
		sErrorMsgOut = "Component can only be assigned to action nodes.";

		return FALSE;
	}

	return TRUE;
}

///
void ActionComponent_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	// Alert: iParamA = const char * or NULL, iParamB = const void * or NULL
	if (ID_OBJECT_ALERT == iID && StrComp(iParamA) == "push") Push(VScriptRM()->GetMasterState());

	else IVObjectComponent::MessageFunction(iID, iParamA, iParamB);
}

///
char ActionComponent_cl::CommonSerialize (VArchive & ar, char iLocalVersion)
{
	char iReadVersion = BeginComponentSerialize(this, ar, iLocalVersion);

	return iReadVersion;
}

/* ActionComponent_cl variables */
V_IMPLEMENT_DYNAMIC(ActionComponent_cl, IVObjectComponent, Vision::GetEngineModule());

START_VAR_TABLE(ActionComponent_cl, IVObjectComponent, "", VFORGE_HIDECLASS, "defaultBox")

END_VAR_TABLE
--]]

--[[
--
--
-- ActionComponents_Alert.cpp
--
--
#include "stdafx.h"
#include "actioncomponents.h"
#include "entitymanager.h"
#include "Lua_/Lua.h"

/// Constructor
Alert_ActionComponent_cl::Alert_ActionComponent_cl (void)
{
	Initialize();
}

///
void Alert_ActionComponent_cl::Push (lua_State * L)
{
	if (Named) ResolveName(GetOwner());

	PUSH_STATIC_PRIVATE_VAR(AlertVar);	// ..., avar
}

///
void Alert_ActionComponent_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{
	GetAttributes(pVar, info);
}

/// Message handler
void Alert_ActionComponent_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	// Get Standard Values: iParamA = "action_alerts", iParamB = VStrList *
	if (VIS_MSG_EDITOR_GETSTANDARDVALUES == iID && StrComp(iParamA) == "global_alerts") SendMsg(GlobalReceiver_cl::GetMe(), iID, INT_PTR("enum_alerts:action"), iParamB);

	// Other cases
	else ActionComponent_cl::MessageFunction(iID, iParamA, iParamB);
}

/// Serialization
void Alert_ActionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	/* VERSION 1 */
	AlertVar::Begin(ar);
	AlertVar::Serialize(ar);
}

/* Alert_ActionComponent_cl variables */
V_IMPLEMENT_SERIAL(Alert_ActionComponent_cl, ActionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(Alert_ActionComponent_cl, ActionComponent_cl, "Sends an alert to this action's referent", VCOMPONENT_ALLOW_MULTIPLE, "'Alert' Action")

	DEFINE_ALERTVAR_DERIVED(Alert_ActionComponent_cl);

END_VAR_TABLE
--]]

--[[
--
--
-- ActionComponents_ArithmeticMutateNum.cpp
--
--
#include "stdafx.h"
#include "actioncomponents.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// Constructor
SimpleMutateNum_ActionComponent_cl::SimpleMutateNum_ActionComponent_cl (void)
{
	Initialize();
}

///
void SimpleMutateNum_ActionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(BaseVar);	// ..., bvar

	lua_pushstring(L, GetEnumValue(this, "Op", Op));// ..., bvar, op
}

/// Serialization
void SimpleMutateNum_ActionComponent_cl::Serialize (VArchive & ar)
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

/// Simple mutate number operations
static const char * Ops = "Decrement,Increment";

STATIC_ENUM_GROUP(ActionEnums,
	{ "actions:simple_mutate_num", Ops }
);

/* SimpleMutateNum_ActionComponent_cl variables */
V_IMPLEMENT_SERIAL(SimpleMutateNum_ActionComponent_cl, ActionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(SimpleMutateNum_ActionComponent_cl, ActionComponent_cl, "Performs a simple change on a number variable", VCOMPONENT_ALLOW_MULTIPLE, "'Simple num variable mutate' Action")

	DEFINE_BASEVAR_DERIVED(SimpleMutateNum_ActionComponent_cl, "Zone", "number", BaseVar::sFamily);
	DEFINE_VAR_ENUM(SimpleMutateNum_ActionComponent_cl, Op, "Operation used to change the number", "Increment", Ops, 0, 0);

END_VAR_TABLE
--]]

--[[
--
--
-- ActionComponents_AssignBool.cpp
--
--
#include "stdafx.h"
#include "actioncomponents.h"
#include "conditionnode.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// Constructor
AssignBool_ActionComponent_cl::AssignBool_ActionComponent_cl (void) : mNode(NULL)
{
	Initialize();
}

///
void AssignBool_ActionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(BaseVar);	// ..., bvar

	StrComp op = GetEnumValue(this, "Op", Op);

	lua_pushstring(L, op);	// ..., bvar, op

	if (op == "SetFromCondition")
	{
		if (!mNode) mNode = CompoundConditionNode_cl::FromObject(GetOwner(), Expression);

		VASSERT(mNode);

		lua_pushstring(L, ReferentKey);	// ..., bvar, op, ref_key
		lua_pushlightuserdata(L, mNode);// ..., bvar, op, ref_key, node
	}
}

///
void AssignBool_ActionComponent_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{ 
	StrComp name(pVar);

	// Hide keys if not assigning from a condition.
	if (name == "Expression" || name == "ReferentKey" || name == "Type") info.m_bHidden = GetEnumValue(this, "Op", Op) != "SetFromCondition";
}

/// Serialization
void AssignBool_ActionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Op;
		ar >> Type;
		ar >> Expression;
		ar >> ReferentKey;
	}

	else
	{
		/* VERSION 1 */
		ar << Op;
		ar << Type;
		ar << Expression;
		ar << ReferentKey;
	}

	/* VERSION 1 */
	BaseVar::Begin(ar);
	BaseVar::Serialize(ar);
}

/// Assign boolean operations
static const char * Ops = "SetTrue,SetFalse,Toggle,SetFromCondition";
static const char * Types = "Entity,LightSource,Path,StaticMeshInstance";

STATIC_ENUM_GROUP(ActionEnums,
	{ "actions:assign_bool", Ops },
	{ "actions:bool_referents", Types }
);

/* AssignBool_ActionComponent_cl variables */
V_IMPLEMENT_SERIAL(AssignBool_ActionComponent_cl, ActionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(AssignBool_ActionComponent_cl, ActionComponent_cl, "Assigns a value to a boolean variable", VCOMPONENT_ALLOW_MULTIPLE, "'Assign bool variable' Action")

	DEFINE_BASEVAR_DERIVED(AssignBool_ActionComponent_cl, "Zone", "boolean", BaseVar::sFamily);
	DEFINE_VAR_ENUM(AssignBool_ActionComponent_cl, Op, "Operation used to assign the bool", "SetTrue", Ops, 0, 0);
	DEFINE_VAR_VSTRING(AssignBool_ActionComponent_cl, Expression, "Expression describing condition clause connections", "", 0, 0, 0);
	DEFINE_VAR_VSTRING(AssignBool_ActionComponent_cl, ReferentKey, "Key of object referring to condition", "", 0, 0, 0);
	DEFINE_VAR_ENUM(AssignBool_ActionComponent_cl, Type, "What kind of object is the referent?", "Entity", Types, 0, 0);

END_VAR_TABLE
--]]

--[[
--
--
-- ActionComponents_AssignNum.cpp
--
--
#include "stdafx.h"
#include "actioncomponents.h"
#include "Lua_/Lua.h"

/// Constructor
AssignNum_ActionComponent_cl::AssignNum_ActionComponent_cl (void)
{
	Initialize();
}

///
void AssignNum_ActionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(NumVar);// ..., nvar
}

///
void AssignNum_ActionComponent_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{
	GetAttributes(pVar, info, true);
}

/// Serialization
void AssignNum_ActionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	/* VERSION 1 */
	NumVar::Begin(ar);
	NumVar::Serialize(ar);
}

/* AssignNum_ActionComponent_cl variables */
V_IMPLEMENT_SERIAL(AssignNum_ActionComponent_cl, ActionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(AssignNum_ActionComponent_cl, ActionComponent_cl, "Assigns a value to a number variable", VCOMPONENT_ALLOW_MULTIPLE, "'Assign num variable' Action")

	DEFINE_NUMVAR_DERIVED_ASSIGN(AssignNum_ActionComponent_cl, "Zone", "Constant", BaseVar::sFamily);

END_VAR_TABLE
--]]

--[[
--
--
-- ActionComponents_Call.cpp
--
--
#include "stdafx.h"
#include "actioncomponents.h"
#include "Lua_/Lua.h"

/// Constructor
Call_ActionComponent_cl::Call_ActionComponent_cl (void)
{
	Initialize();
}

///
void Call_ActionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(CallVar);	// ..., cvar
}

/// Serialization
void Call_ActionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	/* VERSION 1 */
	CallVar::Begin(ar);
	CallVar::Serialize(ar);
}

/* Call_ActionComponent_cl variables */
V_IMPLEMENT_SERIAL(Call_ActionComponent_cl, ActionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(Call_ActionComponent_cl, ActionComponent_cl, "Calls an external or script function (if missing, does nothing)", VCOMPONENT_ALLOW_MULTIPLE, "'Call' Action")

	DEFINE_CALLVAR_DERIVED(Call_ActionComponent_cl, "Zone");

END_VAR_TABLE
--]]

--[[
--
--
-- ActionComponents_Copy.cpp
--
--
#include "stdafx.h"
#include "actioncomponents.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// Constructor
Copy_ActionComponent_cl::Copy_ActionComponent_cl (void)
{
	Initialize();
}

///
void Copy_ActionComponent_cl::Push (lua_State * L)
{
	lua_pushstring(L, GetEnumValue(this, "Type", Type));	// ..., type
	lua_pushlightuserdata(L, &From);	// ..., type, from
	lua_pushlightuserdata(L, &To);	// ..., type, from, to
}

/// Serialization
void Copy_ActionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Type;
	}

	else
	{
		/* VERSION 1 */
		ar << Type;
	}

	/* VERSION 1 */
	BaseVar::Begin(ar);

	From.Serialize(ar);
	To.Serialize(ar);
}

/* Copy_ActionComponent_cl variables */
V_IMPLEMENT_SERIAL(Copy_ActionComponent_cl, ActionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(Copy_ActionComponent_cl, ActionComponent_cl, "Copies one variable to another", VCOMPONENT_ALLOW_MULTIPLE, "'Copy variable' Action")

	DEFINE_VAR_ENUM(Copy_ActionComponent_cl, Type, "Variables type", "Bool", BaseVar::sPrimitiveType, 0, 0);
	DEFINE_BASEVAR_MEMBER(Copy_ActionComponent_cl, From, "Zone", "source variable", BaseVar::sFamily);
	DEFINE_BASEVAR_MEMBER(Copy_ActionComponent_cl, To, "Zone", "target variable", BaseVar::sFamily);

END_VAR_TABLE
--]]

--[[
--
--
-- ActionComponents_OutputVar.cpp
--
--
#include "stdafx.h"
#include "actioncomponents.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// Constructor
OutputVar_ActionComponent_cl::OutputVar_ActionComponent_cl (void)
{
	Initialize();
}

///
void OutputVar_ActionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(BaseVar);	// ..., bvar

	lua_pushstring(L, GetEnumValue(this, "Type", Type));// ..., bvar, type
	lua_pushstring(L, GetEnumValue(this, "Op", Op));// ..., bvar, type, op
}

/// Serialization
void OutputVar_ActionComponent_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Op;
		ar >> Type;
	}

	else
	{
		/* VERSION 1 */
		ar << Op;
		ar << Type;
	}

	/* VERSION 1 */
	BaseVar::Begin(ar);
	BaseVar::Serialize(ar);
}

/// Simple output variable operations
static const char * Ops = "Print,Message";

STATIC_ENUM_GROUP(ActionEnums,
	{ "actions:output_var", Ops }
);

/* OutputVar_ActionComponent_cl variables */
V_IMPLEMENT_SERIAL(OutputVar_ActionComponent_cl, ActionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(OutputVar_ActionComponent_cl, ActionComponent_cl, "Outputs a variable", VCOMPONENT_ALLOW_MULTIPLE, "'Output variable' Action")

	DEFINE_BASEVAR_DERIVED(OutputVar_ActionComponent_cl, "Zone", "variable", BaseVar::sFamily);
	DEFINE_VAR_ENUM(OutputVar_ActionComponent_cl, Op, "Operation used to output the variable", "Print", Ops, 0, 0);
	DEFINE_VAR_ENUM(OutputVar_ActionComponent_cl, Type, "Variable type", "Bool", BaseVar::sType, 0, 0);

END_VAR_TABLE
--]]

--[[
--
--
-- ActionComponents_Timer.cpp
--
--
#include "stdafx.h"
#include "actioncomponents.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// Constructor
Timer_ActionComponent_cl::Timer_ActionComponent_cl (void)
{
	Initialize();
}

///
void Timer_ActionComponent_cl::Push (lua_State * L)
{
	PUSH_STATIC_PRIVATE_VAR(BaseVar);	// ..., bvar

	lua_pushlightuserdata(L, &Duration);// ..., bvar, nvar
	lua_pushstring(L, GetEnumValue(this, "Op", Op));// ..., bvar, nvar, op
}

///
void Timer_ActionComponent_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{
	StrComp name(pVar);

	// Hide the duration for non-Start ops, and otherwise defer to the number behavior.
	if (VStringHelper::StartsWith(name, "Duration."))
	{
		if (GetEnumValue(this, "Op", Op) != "Start") info.m_bHidden = true;

		else Duration.GetAttributes(name, info);
	}
}

/// Serialization
void Timer_ActionComponent_cl::Serialize (VArchive & ar)
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

	NumVar::Begin(ar);
	Duration.Serialize(ar);
}

/// Timer operations
static const char * Ops = "Start,Stop,Pause,Unpause";

STATIC_ENUM_GROUP(ActionEnums,
	{ "actions:timer", Ops }
);

/* Timer_ActionComponent_cl variables */
V_IMPLEMENT_SERIAL(Timer_ActionComponent_cl, ActionComponent_cl, 0, Vision::GetEngineModule());

START_VAR_TABLE(Timer_ActionComponent_cl, ActionComponent_cl, "Performs an operation on a timer variable", VCOMPONENT_ALLOW_MULTIPLE, "'Timer variable' Action")

	DEFINE_BASEVAR_DERIVED(Timer_ActionComponent_cl, "Zone", "timer", BaseVar::sFamily);
	DEFINE_VAR_ENUM(Timer_ActionComponent_cl, Op, "Operation applied to the timer", "Start", Ops, 0, 0);
	DEFINE_NUMVAR_MEMBER(Timer_ActionComponent_cl, Duration, "Duration the timer should run", "Zone", BaseVar::sFamilyEx);

END_VAR_TABLE
--]]