--- ENTITY_VARS from C++.

--[[
--
--
-- EntityVars.h
--
--
#ifndef _ENTITY_VARS
#define _ENTITY_VARS

#include "AppUtils.h"
#include "Enum.h"

// Forward references
struct lua_State;

/// Copy into a static var from a privately derived type and load it into the stack
#define PUSH_STATIC_PRIVATE_VAR(type)	\
	static type s##type;				\
										\
	s##type = *this;					\
										\
	lua_pushlightuserdata(L, &s##type);

/// Common variable part
struct BaseVar {
	static const char * sFamily;///< Variable family names
	static const char * sFamilyEx;	///< Variable family names, and object properties
	static const char * sPrimitiveType;	///< Primitive variable types
	static const char * sType;	///< Variable types

	static char Begin (VArchive & ar);

	void Push (lua_State * L);
	void Serialize (VArchive & ar);

	// vForge variables
	VString Name;	///< Variable name
	int Family;	///< Family to which the variable belongs
};

// Helper op macros
#define NO_PREFIX(_, name) name
#define WITH_PREFIX(prefix, name) prefix##.##name

// Common base var macro definition
#define AUX_DEFINE_BASEVAR(klass, def, what, op, prefix, family)										\
	DEFINE_VAR_ENUM(klass, op(prefix, Family), "Which family is the " what " in?", def, family, 0, 0);	\
	DEFINE_VAR_VSTRING(klass, op(prefix, Name), "Name of " what, "", 0, 0, 0);

/// Define BaseVar variables when this is a base of the class
#define DEFINE_BASEVAR_DERIVED(klass, def, what, families) AUX_DEFINE_BASEVAR(klass, def, what, NO_PREFIX, false, families)

/// Define BaseVar variables when these are a class member
#define DEFINE_BASEVAR_MEMBER(klass, member, def, what, families) AUX_DEFINE_BASEVAR(klass, def, what, WITH_PREFIX, member, families)

/// Call variable part
struct CallVar : public BaseVar {
	static const char * sFamily;///< Variable family names, plus script option

	static char Begin (VArchive & ar);

	void Push (lua_State * L);
	void Serialize (VArchive & ar);

	// vForge variables
	BOOL Bake;	///< If true, the call should be baked in when pushed
	BOOL HasObjectParam;///< If true, the call has an @e object parameter
};

// Common call var macro definition
#define AUX_DEFINE_CALLVAR(klass, def_family, op, prefix)															\
	AUX_DEFINE_BASEVAR(klass, def_family, "called function", op, prefix, CallVar::sFamily);							\
	DEFINE_VAR_BOOL(klass, op(prefix, HasObjectParam), "Does this call take an 'object' argument?", "TRUE", 0, 0);	\
	DEFINE_VAR_BOOL(klass, op(prefix, Bake), "Bake call on initialization?", "FALSE", 0, 0);

/// Define CallVar variables when this is a base of the class
#define DEFINE_CALLVAR_DERIVED(klass, def_family) AUX_DEFINE_CALLVAR(klass, def_family, NO_PREFIX, false)

/// Define CallVar variables when these are a class member
#define DEFINE_CALLVAR_MEMBER(klass, member, def_family) AUX_DEFINE_CALLVAR(klass, def_family, WITH_PREFIX, member)

/// Number variable part
struct NumVar : public BaseVar {
	static const char * sNumberType;///< Number type names
	static const char * sNumberTypeNoVars;	///< Number type names, minus variables

	static char Begin (VArchive & ar);

	void GetAttributes (const StrComp & name, VVariableAttributeInfo & info, bool bShowBaseVar = false);
	void Push (lua_State * L);
	void Serialize (VArchive & ar);

	// vForge variables
	float Bound1;	///< Random range boundary #1
	float Bound2;	///< Random range boundary #2
	float Value;///< Value used by constant type
	int Type;	///< Index for @b "num_type" enumeration
};

// Common num var macro definition
#define AUX_DEFINE_NUMVAR(klass, def_family, def_type, op, prefix, what, num_types, families)				\
	AUX_DEFINE_BASEVAR(klass, def_family, "number variable", op, prefix, families);							\
	DEFINE_VAR_ENUM(klass, op(prefix, Type), "What type of number is " what "?", def_type, num_types, 0, 0);\
	DEFINE_VAR_FLOAT(klass, op(prefix, Bound1), "Bound #1 if number is random", "0", 0, 0);					\
	DEFINE_VAR_FLOAT(klass, op(prefix, Bound2), "Bound #2 if number is random", "1", 0, 0);					\
	DEFINE_VAR_FLOAT(klass, op(prefix, Value), "Value if number is a constant", "0", 0, 0);

/// Define NumVar variables when this is a base of the class
#define DEFINE_NUMVAR_DERIVED(klass, def_family, def_type, families) AUX_DEFINE_NUMVAR(klass, def_family, def_type, NO_PREFIX, false, "this", NumVar::sNumberType, families)

/// Define NumVar variables when these are a class member
#define DEFINE_NUMVAR_MEMBER(klass, member, def_family, def_type, families) AUX_DEFINE_NUMVAR(klass, def_family, def_type, WITH_PREFIX, member, "this", NumVar::sNumberType, families)

/// Define NumVar variables when this is a base of the class, being assigned another non-variable number
#define DEFINE_NUMVAR_DERIVED_ASSIGN(klass, def_family, def_type, families) AUX_DEFINE_NUMVAR(klass, def_family, def_type, NO_PREFIX, false, "being assigned", NumVar::sNumberTypeNoVars, families)

/// Define NumVar variables when these are a class member, being assigned another non-variable number
#define DEFINE_NUMVAR_MEMBER_ASSIGN(klass, member, def_family, def_type, families) AUX_DEFINE_NUMVAR(klass, def_family, def_type, WITH_PREFIX, member, "being assigned", NumVar::sNumberTypeNoVars, families)

/// Alert variable part
struct AlertVar {
	static const char * sPayloadType;	///< Payload type names

	static char Begin (VArchive & ar);

	void GetAttributes (const StrComp & name, VVariableAttributeInfo & info);
	void Push (lua_State * L);
	void ResolveName (VisTypedEngineObject_cl * pObject, const char * how = NULL);
	void Serialize (VArchive & ar);

	// vForge variables
	VString Alert;	///< Alert to send
	VString String;	///< Payload when @e PayloadType is @b "String"
	BOOL Global;///< If true, alert is sent to the global receiver and not the current object
	BOOL Named;	///< If true, @e Alert is a lookup name
	int PayloadType;///< Index for @b "alert_payload" type
};

// Common alert var macro definition
#define AUX_DEFINE_ALERT_VAR(klass, op, prefix)																										\
	DEFINE_VAR_VSTRING(klass, op(prefix, Alert), "Alert being sent", "", 0, 0, 0);																	\
	DEFINE_VAR_VSTRING(klass, op(prefix, String), "String payload", "", 0, 0, 0);																	\
	DEFINE_VAR_BOOL(klass, Global, "Is this alert global, instead of directed at an object?", "FALSE", 0, 0);										\
	DEFINE_VAR_BOOL(klass, Named, "Is the alert string a lookup name for a parameter component?", "FALSE", 0, 0);									\
	DEFINE_VAR_ENUM(klass, op(prefix, PayloadType), "What kind of payload are we attaching to the alert?", "None", AlertVar::sPayloadType, 0, 0);	\
	DEFINE_VAR_STRING_CALLBACK(klass, GlobalAlerts, "List of recognized global alerts", "", 0, "dropdown(global_alerts)");

/// Define AlertVar variables when this is a base of the class
#define DEFINE_ALERTVAR_DERIVED(klass) AUX_DEFINE_ALERT_VAR(klass, NO_PREFIX, false)

/// Define AlertVar variables when these are a class member
#define DEFINE_ALERTVAR_MEMBER(klass, member) AUX_DEFINE_ALERT_VAR(klass, WITH_PREFIX, member)

// Broadcast variable part
struct BroadcastVar {
	static const char * sGroupType;	///< Group type names

	static char Begin (VArchive & ar);

	void GetAttributes (const StrComp & name, VVariableAttributeInfo & info);
	void Push (lua_State * L);
	void Serialize (VArchive & ar);

	// vForge variables
	VString Constraint;	///< Optional constraint expression (cf. CompoundConditionNode_cl) for filtering
	VString EntityType;	///< Optional sub-type for filtering, if @e GroupType specifies broadcasts to entities
	VString RecipientsKey;	///< Optional key for filtering
	int GroupType;	///< Index for @b "broadcast_group" type
};

// Common broadcast var macro definition
#define AUX_DEFINE_BROADCAST_VAR(klass, op, prefix)																					\
	DEFINE_VAR_VSTRING(klass, op(prefix, Constraint), "Constraint expression describing condition clause connections", "", 0, 0, 0);\
	DEFINE_VAR_VSTRING(klass, op(prefix, EntityType), "What kind of entity?", "Any", 0, 0, "dropdown(entity_type)");				\
	DEFINE_VAR_VSTRING(klass, op(prefix, RecipientsKey), "Key for valid objects", "", 0, 0, 0);										\
	DEFINE_VAR_ENUM(klass, op(prefix, GroupType), "Broadcast to what group?", "None", BroadcastVar::sGroupType, 0, 0);

// Define BroadcastVar variables when this is a base of the class
#define DEFINE_BROADCASTVAR_DERIVED(klass) AUX_DEFINE_BROADCAST_VAR(klass, NO_PREFIX, false)

// Define BroadcastVar variables when these are a class member
#define DEFINE_BROADCASTVAR_MEMBER(klass, member) AUX_DEFINE_BROADCAST_VAR(klass, WITH_PREFIX, member)

#endif
--]]

--[[
--
--
-- EntityVars.cpp
--
--
#include "stdafx.h"
#include "namedparamcomponent.h"
#include "entityvars.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/* Strings used by base vars */
const char * BaseVar::sFamily = "Zone,Scene,Global";
const char * BaseVar::sFamilyEx = "Zone,Scene,Global,ObjectProperty,GlobalProperty";
const char * BaseVar::sPrimitiveType = "Bool,Number,Raw";
const char * BaseVar::sType = "Bool,Number,Raw,Timer,Delegate";

/* Strings used by call vars */
const char * CallVar::sFamily = "Zone,Scene,Global,Script";

/* Strings used by num vars */
const char * NumVar::sNumberType = "Constant,RandomInteger,RandomNumber,Variable";
const char * NumVar::sNumberTypeNoVars = "Constant,RandomInteger,RandomNumber";

/* Strings used by alert vars */
const char * AlertVar::sPayloadType = "None,True,False,String";

/* Strings used by broadcast vars */
const char * BroadcastVar::sGroupType = "Players,Enemies,Entities,Paths,Light Sources,Convex Volumes,Static Mesh Instances";

/// For possible future use
/// @return Read version number, or 0xFF if saving
char BaseVar::Begin (VArchive & ar)
{
	return char(0xFF);
}

/// Metacompiler push logic
void BaseVar::Push (lua_State * L)
{
	lua_pushstring(L, Enum_cl::GetMe()->GetKey("var_family_ex", Family));	// ..., family
	lua_pushstring(L, Name);// ..., family, name
}	

/// Serialization
void BaseVar::Serialize (VArchive & ar)
{
	if (ar.IsLoading())
	{
		ar >> Name;
		ar >> Family;
	}

	else
	{
		ar << Name;
		ar << Family;
	}
}

/// Prepare to serialize one or more call vars
/// @return Read version number, or 0xFF if saving
char CallVar::Begin (VArchive & ar)
{
	const char VERSION = 1;

	return BeginVersionedSerialize(ar, VERSION);
}

/// Metacompiler push logic
void CallVar::Push (lua_State * L)
{
	bool from_script = Enum_cl::GetMe()->Get("call_family", "Script") == Family;

	lua_pushboolean(L, from_script);// ..., from_script

	if (from_script) lua_pushstring(L, Name);	// ..., true, name

	else lua_pushlightuserdata(L, this);// ..., false, bvar

	lua_pushboolean(L, Bake);	// ..., from_script, name / bvar, bake
	lua_pushboolean(L, HasObjectParam);	// ..., from_script, name / bvar, bake, has_object_param
}

/// Serialization
void CallVar::Serialize (VArchive & ar)
{
	if (ar.IsLoading())
	{
		ar >> Bake;
		ar >> HasObjectParam;
	}

	else
	{
		/* VERSION 1 */
		ar << Bake;
		ar << HasObjectParam;
	}

	/* VERSION 1 */
	BaseVar::Begin(ar);
	BaseVar::Serialize(ar);
}

/// Prepare to serialize one or more num vars
/// @return Read version number, or 0xFF if saving
char NumVar::Begin (VArchive & ar)
{
	const char VERSION = 1;

	return BeginVersionedSerialize(ar, VERSION);
}

/// Gets attributes belonging to this num var
void NumVar::GetAttributes (const StrComp & name, VVariableAttributeInfo & info, bool bShowBaseVar)
{
	// Hide irrelevant fields.
	StrComp type = Enum_cl::GetMe()->GetKey("num_type", Type);

	Enum_cl::GetMe()->Close();

	if (EndsWith(name, "Family") || EndsWith(name, "Name")) info.m_bHidden = type != "Variable" && !bShowBaseVar;
	else if (EndsWith(name, "Value")) info.m_bHidden = type != "Constant";
	else if (EndsWith(name, '1') || EndsWith(name, '2')) info.m_bHidden = type != "RandomInteger" && type != "RandomNumber";
}

/// Metacompiler push logic
void NumVar::Push (lua_State * L)
{
	StrComp type = Enum_cl::GetMe()->GetKey("num_type", Type);

	lua_pushstring(L, type);// ..., type

	if (type == "Constant") lua_pushnumber(L, Value);	// ..., type, value

	else if (type != "Variable")
	{
		VASSERT(type == "RandomInteger" || type == "RandomNumber");

		lua_pushnumber(L, Bound1);	// ..., type, bound1
		lua_pushnumber(L, Bound2);	// ..., type, bound1, bound2
	}
}

/// Serialization
void NumVar::Serialize (VArchive & ar)
{
	if (ar.IsLoading())
	{
		ar >> Bound1;
		ar >> Bound2;
		ar >> Value;
		ar >> Type;
	}

	else
	{
		/* VERSION 1 */
		ar << Bound1;
		ar << Bound2;
		ar << Value;
		ar << Type;
	}

	/* VERSION 1 */
	BaseVar::Begin(ar);
	BaseVar::Serialize(ar);
}

/// Prepare to serialize one or more alert vars
/// @return Read version number, or 0xFF if saving
char AlertVar::Begin (VArchive & ar)
{
	const char VERSION = 1;

	return BeginVersionedSerialize(ar, VERSION);
}

/// Gets attributes belonging to this alert var
void AlertVar::GetAttributes (const StrComp & name, VVariableAttributeInfo & info)
{
	// Hide string when not using it as a payload.
	if (EndsWith(name, "String"))
	{
		StrComp type = Enum_cl::GetMe()->GetKey("alert_payload", PayloadType);

		Enum_cl::GetMe()->Close();

		info.m_bHidden = type != "String";
	}

	// Hide alerts list if not global.
	if (EndsWith(name, "GlobalAlerts")) info.m_bHidden = !Global;

}

/// Metacompiler push logic
void AlertVar::Push (lua_State * L)
{
	lua_pushstring(L, Alert);	// ..., alert

	StrComp type = Enum_cl::GetMe()->GetKey("alert_payload", PayloadType);

	lua_pushstring(L, type);// ..., alert, type
	lua_pushboolean(L, Global);	// ..., alert, type, global

	if (type == "String") lua_pushstring(L, String);// ..., alert, type, global[, string]
}

/// Resolve alert from name
/// @param pObject Object that may hold named param
/// @param how Resolution type
void AlertVar::ResolveName (VisTypedEngineObject_cl * pObject, const char * how)
{
	VASSERT(pObject);

	NamedParamComponent_cl * npc = NamedParamComponent_cl::FindFirstWithName(pObject, Alert.AsChar(), how);

	if (!npc || !npc->GetString(Alert)) Alert = "";
}

/// Serialization
void AlertVar::Serialize (VArchive & ar)
{
	if (ar.IsLoading())
	{
		ar >> Alert;
		ar >> String;
		ar >> Global;
		ar >> Named;
		ar >> PayloadType;
	}

	else
	{
		/* VERSION 1 */
		ar << Alert;
		ar << String;
		ar << Global;
		ar << Named;
		ar << PayloadType;
	}
}

/// Prepare to serialize one or more broadcast vars
/// @return Read version number, or 0xFF if saving
char BroadcastVar::Begin (VArchive & ar)
{
	const char VERSION = 1;

	return BeginVersionedSerialize(ar, VERSION);
}

/// Gets attributes belonging to this broadcast var
void BroadcastVar::GetAttributes (const StrComp & name, VVariableAttributeInfo & info)
{
	if (!EndsWith(name, "String")) return;

	// Gray out type list when not broadcasting to entities.
	StrComp type = Enum_cl::GetMe()->GetKey("broadcast_group", GroupType);

	Enum_cl::GetMe()->Close();

	info.m_bReadOnly = type != "Entities";
}

/// Metacompiler push logic
void BroadcastVar::Push (lua_State * L)
{
	lua_pushstring(L, Constraint);	// ..., constraint
	lua_pushstring(L, RecipientsKey);	// ..., constraint, recipients_key

	StrComp type = Enum_cl::GetMe()->GetKey("broadcast_group", GroupType);

	lua_pushstring(L, type);// ..., constraint, recipients_key, type

	if (type == "Entities") lua_pushstring(L, EntityType);	// ..., constraint, recipients_key, type[, entity_type]
}

/// Serialization
void BroadcastVar::Serialize (VArchive & ar)
{
	if (ar.IsLoading())
	{
		ar >> Constraint;
		ar >> EntityType;
		ar >> RecipientsKey;
		ar >> GroupType;
	}

	else
	{
		/* VERSION 1 */
		ar << Constraint;
		ar << EntityType;
		ar << RecipientsKey;
		ar << GroupType;
	}
}

// Load common variable enums.
STATIC_ENUM_GROUP(CommonEnums,
	{ "alert_payload", AlertVar::sPayloadType },
	{ "broadcast_group", BroadcastVar::sGroupType },
	{ "call_family", CallVar::sFamily },
	{ "num_type", NumVar::sNumberType },
	{ "var_family", BaseVar::sFamily },
	{ "var_family_ex", BaseVar::sFamilyEx }
);
--]]