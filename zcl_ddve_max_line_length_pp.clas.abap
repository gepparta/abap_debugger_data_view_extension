"! Initially created by Andreas Kopp
"! This class is a pretty printer for abap value # expression
"! It consider a max line length of 128 chars
CLASS zcl_ddve_max_line_length_pp DEFINITION
  PUBLIC
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_ddve_prettyprinter_factory. " needed for instantiation

  PUBLIC SECTION.
    INTERFACES zif_ddve_value_pretty_printer.

    ALIASES format FOR zif_ddve_value_pretty_printer~format.

    "! @parameter i_indent_size     | Number of spaces to begin each line with
    "! @parameter i_max_line_length | Maximum number of characters for each line. Value has
    "! to be between 20 and 255 characters (maximum of ABAP editor).
    METHODS constructor
      IMPORTING i_indent_size     TYPE i DEFAULT 2
                i_max_line_length TYPE i DEFAULT 128.

  PROTECTED SECTION.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_block,
             id             TYPE i,
             group_id       TYPE i,
             char           TYPE c LENGTH 1,
             level_of_depth TYPE i,
             line_index     TYPE i,
             " block is completed when '(' and ')' for the same group_id exists
             is_completed   TYPE abap_bool,
           END OF ty_block,
           ty_block_table TYPE SORTED TABLE OF ty_block WITH UNIQUE KEY id,
           ty_lines       TYPE TABLE OF string WITH DEFAULT KEY.

    DATA:
      indent_size     TYPE i,
      max_line_length TYPE i,
      reader          TYPE REF TO cl_abap_string_c_reader,
      blocks          TYPE ty_block_table,
      current_line    TYPE string,
      output_lines    TYPE ty_lines.

    CONSTANTS:
      c_newline          TYPE abap_char1 VALUE cl_abap_char_utilities=>cr_lf,
      c_opening_bracket  TYPE c LENGTH 1 VALUE '(',
      c_closing_bracket  TYPE c LENGTH 1 VALUE ')',
      c_enclosure        TYPE c LENGTH 1 VALUE '''',
      c_enclosure_escape TYPE c LENGTH 1 VALUE '''',
      c_concatenate      TYPE c LENGTH 1 VALUE '&'.

    METHODS:
      get_lines_as_string
        RETURNING VALUE(r_string) TYPE string,

      "! Processes next char read by reader
      "!
      "! @parameter i_char |
      handle_char
        IMPORTING i_char TYPE string,

      "! Reads component value that is between enclosure characters (respecting enclosure escapes).
      "! Example: Returns "It''s easy (isn''t it?)" from "[COL =] 'It''s easy (isn''t it?)' ".
      "!
      "! @parameter r_value |
      read_value_between_enclosures
        RETURNING VALUE(r_value) TYPE string,

      "! Splits value into several lines. The length of each line is less than the maximum line size.
      "! The remaining characters of the first line can be used to fill up the first line.
      "!
      "! @parameter i_length_of_first_line | characters already used for the first line
      "! @parameter i_value | value to split up
      "! @parameter i_indent_size | number of spaces to begin each line beginning from the second line
      "! @parameter r_parts |
      split_value_at_max_line_length
        IMPORTING i_length_of_first_line TYPE i
                  i_value                TYPE string
                  i_indent_size          TYPE i OPTIONAL
        RETURNING VALUE(r_parts)         TYPE ty_lines,

      add_to_block_control
        IMPORTING i_char         TYPE string
                  i_line_index   TYPE i
        RETURNING VALUE(r_block) TYPE ty_block,

      "! Calculates number of spaces for the next line.
      "! Previous line has to be appended already to output_lines and block control must exist.
      "!
      "! @parameter r_spaces |
      calculate_indent
        RETURNING VALUE(r_spaces) TYPE string,

      calculate_level_of_depth
        IMPORTING i_char                  TYPE string
        RETURNING VALUE(r_level_of_depth) TYPE i,

      calculate_group_id
        IMPORTING i_char            TYPE string
        RETURNING VALUE(r_group_id) TYPE i,

      append_line,
      update_indent_of_last_line,
      clear_members.
ENDCLASS.


CLASS zcl_ddve_max_line_length_pp IMPLEMENTATION.
  METHOD add_to_block_control.
    DATA block LIKE LINE OF blocks.

    " Example:           Line
    " D = VALUE #(          1
    " COL1 = '(1)'          2
    " COL2 = VALUE #(       3
    " COL1 = '1'            4
    " COL2 = '2'            5
    " COL3 = 'It''s easy'   6
    ")                     7
    " COL3 = '3'            8
    " COL4 = VALUE #(       9
    " COL1 = '1'           10
    " COL2 = '2'           11
    ")                    12
    ").                   13

    " Blocks:
    "|ID |GROUP|CHAR|LEVEL|LINE
    "|1  |1    |(   |1    |1
    "|2  |2    |(   |2    |3
    "|3  |2    |)   |2    |7
    "|4  |3    |(   |2    |9
    "|5  |3    |)   |2    |12
    "|6  |1    |)   |1    |13

    " Blocks that belong together have the same group id.
    " Each block starts with '(' and ends with ')'.
    CHECK    i_char = c_opening_bracket
          OR i_char = c_closing_bracket.

    block-id             = lines( blocks ) + 1.
    block-char           = i_char.
    block-line_index     = i_line_index.
    block-level_of_depth = calculate_level_of_depth( i_char ).
    block-group_id       = calculate_group_id( i_char ).

    " With the closing bracket, a group of two blocks (with the same group id) is complete.
    IF i_char = c_closing_bracket.
      block-is_completed = abap_true.
      ASSIGN blocks[ group_id = block-group_id ] TO FIELD-SYMBOL(<opening_block>).
      IF sy-subrc = 0.
        <opening_block>-is_completed = abap_true.
      ENDIF.
    ENDIF.

    APPEND block TO blocks.
  ENDMETHOD.

  METHOD append_line.
    APPEND current_line TO output_lines.
    CLEAR current_line.
  ENDMETHOD.

  METHOD calculate_group_id.
    DATA excluded_group_ids TYPE TABLE OF ty_block-group_id.

    DATA(index) = lines( blocks ).

    " each opening bracket starts a new group
    IF i_char = c_opening_bracket.
      r_group_id = COND #( WHEN index > 0
                           THEN blocks[ index ]-group_id + 1
                           ELSE 1 ).
      RETURN.
    ENDIF.

    " find matching opening bracket for each closing bracket
    " and assign group id of corresponding opening bracket
    IF i_char = c_closing_bracket.
      WHILE index > 0.
        ASSIGN blocks[ index ] TO FIELD-SYMBOL(<block>).
        IF <block>-char = c_closing_bracket.
          " group is already closed so exclude its group_id
          APPEND <block>-group_id TO excluded_group_ids.
        ELSEIF         <block>-char = c_opening_bracket
               AND NOT line_exists( excluded_group_ids[ table_line = <block>-group_id ] ).
          " opening bracket found which is not closed yet
          r_group_id = <block>-group_id.
          RETURN.
        ENDIF.
        index = index - 1.
      ENDWHILE.
    ENDIF.
  ENDMETHOD.

  METHOD calculate_indent.
    DATA level TYPE ty_block-level_of_depth.

    IF lines( output_lines ) < 1.
      RETURN.
    ENDIF.
    DATA(last_line) = output_lines[ lines( output_lines ) ].
    DATA(last_char_of_last_line) = substring( val = last_line
                                              off = strlen( last_line ) - 1 ).

    CASE last_char_of_last_line.
      WHEN c_opening_bracket OR c_closing_bracket.
        level = blocks[ lines( blocks ) ]-level_of_depth - 1.
      WHEN c_enclosure OR c_concatenate.
        " find latest block that is not completed
        DATA(block_index) = lines( blocks ).
        WHILE block_index > 0.
          IF blocks[ block_index ]-is_completed = abap_false.
            level = blocks[ block_index ]-level_of_depth.
            EXIT.
          ENDIF.
          block_index = block_index - 1.
        ENDWHILE.
    ENDCASE.

    DATA(number_of_spaces) = level * indent_size.
    DO number_of_spaces TIMES.
      r_spaces = |{ r_spaces } |.
    ENDDO.
  ENDMETHOD.

  METHOD calculate_level_of_depth.
    DATA(index) = lines( blocks ).
    IF index = 0.
      " first entry
      r_level_of_depth = 1.
      RETURN.
    ENDIF.
    DATA(previous_block) = blocks[ index ].
    r_level_of_depth = COND #(
      WHEN i_char = c_opening_bracket AND previous_block-char = c_closing_bracket
        OR i_char = c_closing_bracket AND previous_block-char = c_opening_bracket THEN previous_block-level_of_depth
      WHEN i_char = c_opening_bracket AND previous_block-char = c_opening_bracket THEN previous_block-level_of_depth + 1
      WHEN i_char = c_closing_bracket AND previous_block-char = c_closing_bracket THEN previous_block-level_of_depth - 1 ).
  ENDMETHOD.

  METHOD constructor.
    indent_size = i_indent_size.
    max_line_length = COND #(
      WHEN i_max_line_length >= 20 AND i_max_line_length <= 255
      THEN i_max_line_length
      ELSE 128 ).
  ENDMETHOD.

  METHOD get_lines_as_string.
    DATA(writer) = NEW cl_abap_string_c_writer( ).

    LOOP AT output_lines ASSIGNING FIELD-SYMBOL(<line>).
      IF sy-tabix > 1.
        writer->write( |{ c_newline }| ).
      ENDIF.
      writer->write( <line> ).
    ENDLOOP.

    writer->close( ).
    r_string = writer->get_result_string( ).
  ENDMETHOD.

  METHOD handle_char.
    " Skip blanks between brackets and components
    IF current_line CO space AND i_char CO space.       " EQ space does not work
      RETURN.
    ENDIF.

    IF i_char = c_enclosure.
      DATA(value) = read_value_between_enclosures( ).
      DATA(parts) = split_value_at_max_line_length( i_length_of_first_line = strlen( current_line )  " to fill up current line
                                                    i_value                = value
                                                    i_indent_size          = strlen( calculate_indent( ) ) ).  " indent size needed for split calculation
      LOOP AT parts INTO DATA(part).
        current_line = current_line && part.
        append_line( ).
        update_indent_of_last_line( ).
      ENDLOOP.
      RETURN.
    ENDIF.

    current_line = current_line && i_char.

    IF    i_char = c_opening_bracket
       OR i_char = c_closing_bracket.
      append_line( ).                          " append line first
      add_to_block_control(                    " block control expects that line is appended
                            i_char       = i_char
                            i_line_index = lines( output_lines ) ).
      update_indent_of_last_line( ).           " indent calculation requires block control
    ENDIF.
  ENDMETHOD.

  METHOD read_value_between_enclosures.
    DATA char TYPE string.

    DATA(value) = | { c_enclosure }|.
    DO.
      char = reader->read( 1 ).
      value = value && char.
      "^[ ](['].*['])[ ]$ extracts value surrounded by enclosures
      "^[ ]['](.*)['][ ]$ extracts value only
      DATA(matcher) = cl_abap_matcher=>create( pattern = |^[ ]([{ c_enclosure }].*[{ c_enclosure }])[ ]$|
                                               text    = value ).
      IF matcher->match( ) = abap_true.
        r_value = matcher->get_submatch( 1 ).
        RETURN.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD split_value_at_max_line_length.
    DATA part TYPE string.

    " if max length is not exceeded, just return input value.
    IF i_length_of_first_line + strlen( i_value ) <= max_line_length.
      APPEND i_value TO r_parts.
      RETURN.
    ENDIF.

    DATA(max_length) = max_line_length - i_length_of_first_line - i_indent_size.  " first line is shorter
    DATA(value_length) = strlen( i_value ).
    DATA(offset) = 0.
    WHILE offset < value_length.
      " an escaped enclosure ('') is one atomic token - it must never be split across lines;
      " pairs can only occur strictly inside the surrounding enclosures
      DATA(token_length) = COND i( WHEN     offset > 0
                                        AND offset < value_length - 2
                                        AND substring( val = i_value off = offset     len = 1 ) = c_enclosure
                                        AND substring( val = i_value off = offset + 1 len = 1 ) = c_enclosure_escape
                                   THEN 2
                                   ELSE 1 ).
      IF strlen( part ) >= ( max_length - 4 ).  " 4 chars for closing enclosure, space and &&
        APPEND |{ part }{ c_enclosure } { c_concatenate }{ c_concatenate }| TO r_parts.
        part = |{ c_enclosure }|.           " starting with indent and a opening enclosure
        DO i_indent_size TIMES.
          part = | { part }|.
        ENDDO.
        max_length = max_line_length.     " full line length beginning at 2nd line
      ENDIF.
      part = part && substring( val = i_value
                                off = offset
                                len = token_length ).
      offset = offset + token_length.
    ENDWHILE.
    IF part IS NOT INITIAL.
      APPEND |{ part }| TO r_parts.
    ENDIF.
  ENDMETHOD.

  METHOD update_indent_of_last_line.
    ASSIGN output_lines[ lines( output_lines ) ] TO FIELD-SYMBOL(<last_line>).
    SHIFT <last_line> LEFT DELETING LEADING space.
    <last_line> = |{ calculate_indent( ) }{ <last_line> }|.
  ENDMETHOD.

  METHOD zif_ddve_value_pretty_printer~format.
    DATA " work throughout with strings as spaces are preserved
         char TYPE string.

    clear_members( ).

    " an inline declaration DATA(name) on the LHS must not enter the
    " bracket-based block control - keep it verbatim on the first line
    DATA(content) = i_unformated_value_content.
    FIND PCRE '^DATA\([^)]+\)' IN content MATCH LENGTH DATA(prefix_length).
    IF sy-subrc = 0.
      current_line = substring( val = content
                                len = prefix_length ).
      content = substring( val = content
                           off = prefix_length ).
    ENDIF.

    reader = NEW cl_abap_string_c_reader( str = content ).

    WHILE reader->data_available( ) = abap_true.
      char = reader->read( 1 ).
      handle_char( char ).
    ENDWHILE.
    reader->close( ).

    r_formated_content = get_lines_as_string( ).
  ENDMETHOD.

  METHOD clear_members.
    CLEAR: reader,
           blocks,
           current_line,
           output_lines.
  ENDMETHOD.
ENDCLASS.
