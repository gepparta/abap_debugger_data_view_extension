"! Interface for pretty printing a value #() construct
INTERFACE zif_ddve_value_pretty_printer
  PUBLIC .

  METHODS:
    "! Method for formatting given string value,<br/>
    "! which should already be a syntax correct representation of an value #() construct<br/>
    "! See unit test of zcl_ddve_value_pretty_printer class for usage scenarios<br/>
    "! @parameter i_unformatted_value_content | syntax correct representation of an value #() construct
    "! @parameter r_formatted_content | formatted value #() construct containing line breaks, spaces and so on
    format
      IMPORTING i_unformatted_value_content TYPE string
      RETURNING VALUE(r_formatted_content)  TYPE string.

ENDINTERFACE.
