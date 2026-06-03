CLASS zcl_ddve_abap_typedescr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS typekind_int     TYPE abap_typekind VALUE 'I' ##NO_TEXT.
    CONSTANTS typekind_int1    TYPE abap_typekind VALUE 'b' ##NO_TEXT.
    CONSTANTS typekind_int2    TYPE abap_typekind VALUE 's' ##NO_TEXT.
    " in 7.40 there is no int8 but in s4hana there is one
    " having this constants in z-class gives little upward compatibility
    CONSTANTS typekind_int8    TYPE abap_typekind VALUE '8' ##NO_TEXT.
    CONSTANTS typekind_struct1 TYPE abap_typekind VALUE 'u' ##NO_TEXT.
    CONSTANTS typekind_struct2 TYPE abap_typekind VALUE 'v' ##NO_TEXT.
    CONSTANTS typekind_table   TYPE abap_typekind VALUE 'h' ##NO_TEXT.
    CONSTANTS typekind_string  TYPE abap_typekind VALUE 'g' ##NO_TEXT.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_DDVE_ABAP_TYPEDESCR IMPLEMENTATION.
ENDCLASS.
