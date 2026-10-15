"! Translates absolute type names from the ABAP Debugger
"! (e.g. \CLASS=ZCL_X\TYPE=TY_Y) into type expressions that are valid
"! source code for typed VALUE statements: VALUE zcl_x=>ty_y( ... ).
"! Assumption: the generated statement is used inside a unit test that can
"! access private and local types (LOCAL FRIENDS resp. same include).
CLASS zcl_ddve_type_resolver DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      "! translate an absolute type name into a type expression for VALUE typ( )
      "! @parameter i_abs_type_name   | absolute type name (TPDA varabstypename)
      "! @parameter r_type_expression | type expression; empty when not resolvable
      resolve
        IMPORTING i_abs_type_name          TYPE csequence
        RETURNING VALUE(r_type_expression) TYPE string,

      "! derive a variable name for DATA(name) from a debugger symbol name
      "! @parameter i_symbol_name   | debugger symbol name, e.g. a field symbol or ITAB[]
      "! @parameter r_variable_name | valid variable name; empty when not derivable
      derive_variable_name
        IMPORTING i_symbol_name          TYPE csequence
        RETURNING VALUE(r_variable_name) TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF t_segment,
             kind TYPE string,
             name TYPE string,
           END OF t_segment,
           tt_segment TYPE STANDARD TABLE OF t_segment WITH DEFAULT KEY.

    METHODS:
      split_into_segments
        IMPORTING i_abs_type_name   TYPE string
        RETURNING VALUE(r_segments) TYPE tt_segment,

      build_expression
        IMPORTING i_segments               TYPE tt_segment
        RETURNING VALUE(r_type_expression) TYPE string,

      is_valid_identifier
        IMPORTING i_name            TYPE string
        RETURNING VALUE(r_is_valid) TYPE abap_bool.
ENDCLASS.


CLASS zcl_ddve_type_resolver IMPLEMENTATION.
  METHOD resolve.
    DATA(abs_type_name) = to_upper( condense( CONV string( i_abs_type_name ) ) ).
    CHECK abs_type_name IS NOT INITIAL.

    IF NOT contains( val = abs_type_name
                     sub = '\' ).
      " plain name without path: global/DDIC type
      r_type_expression = COND #( WHEN is_valid_identifier( abs_type_name ) = abap_true
                                  THEN abs_type_name ).
      RETURN.
    ENDIF.

    r_type_expression = build_expression( split_into_segments( abs_type_name ) ).
  ENDMETHOD.

  METHOD build_expression.
    CHECK lines( i_segments ) >= 1.

    DATA(type_segment) = i_segments[ lines( i_segments ) ].
    CHECK type_segment-kind = 'TYPE'.
    CHECK is_valid_identifier( type_segment-name ) = abap_true.

    " procedure-local types are not addressable from a unit test
    CHECK NOT line_exists( i_segments[ kind = 'METHOD' ] ).
    CHECK NOT line_exists( i_segments[ kind = 'FORM' ] ).
    CHECK NOT line_exists( i_segments[ kind = 'FUNCTION' ] ).

    IF lines( i_segments ) = 1.
      " \TYPE=NAME: globally visible type (DDIC)
      r_type_expression = type_segment-name.
      RETURN.
    ENDIF.

    DATA(container) = i_segments[ lines( i_segments ) - 1 ].

    CASE container-kind.
      WHEN 'TYPE-POOL' OR 'PROGRAM' OR 'CLASS-POOL' OR 'FUNCTION-POOL'.
        " addressable by plain name: type pools globally,
        " program/pool locals from a test in the same main program
        r_type_expression = type_segment-name.
      WHEN 'CLASS' OR 'INTERFACE'.
        " global or local class/interface: address via =>
        " (private types are reachable through LOCAL FRIENDS)
        r_type_expression = COND #( WHEN is_valid_identifier( container-name ) = abap_true
                                    THEN |{ container-name }=>{ type_segment-name }| ).
      WHEN OTHERS.
        CLEAR r_type_expression.
    ENDCASE.
  ENDMETHOD.

  METHOD split_into_segments.
    SPLIT i_abs_type_name AT '\' INTO TABLE DATA(raw_segments).
    LOOP AT raw_segments INTO DATA(raw_segment) WHERE table_line IS NOT INITIAL.
      SPLIT raw_segment AT '=' INTO DATA(kind) DATA(name).
      APPEND VALUE t_segment( kind = kind
                              name = name ) TO r_segments.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_valid_identifier.
    r_is_valid = xsdbool( matches( val  = i_name
                                   pcre = `(/[A-Z0-9_]{1,8}/)?[A-Z_][A-Z0-9_]*` ) ).
  ENDMETHOD.

  METHOD derive_variable_name.
    DATA(candidate) = to_upper( condense( CONV string( i_symbol_name ) ) ).

    " strip header-line suffix [] and field-symbol brackets <>
    REPLACE ALL OCCURRENCES OF '[]' IN candidate WITH ``.
    TRANSLATE candidate USING '< > '.
    CONDENSE candidate NO-GAPS.

    r_variable_name = COND #( WHEN is_valid_identifier( candidate ) = abap_true
                              THEN candidate ).
  ENDMETHOD.
ENDCLASS.
