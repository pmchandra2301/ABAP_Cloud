CLASS zcl_material_api_client DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_payload,
        material        TYPE string,
        material_type   TYPE string,
        industry_sector TYPE string,
        base_unit       TYPE string,
        description     TYPE string,
        action          TYPE string,
      END OF ty_payload,
      BEGIN OF ty_result,
        success           TYPE abap_boolean,
        external_material TYPE string,
        message           TYPE string,
      END OF ty_result.

    CLASS-METHODS submit
      IMPORTING
        is_payload TYPE ty_payload
      RETURNING
        VALUE(rs_result) TYPE ty_result.

  PRIVATE SECTION.
    CONSTANTS c_destination TYPE string VALUE 'SAP_MATERIAL_API'.
    CONSTANTS c_service_path TYPE string VALUE '/sap/opu/odata/sap/API_MATERIAL_SRV'.

    CLASS-METHODS json_escape
      IMPORTING iv_value TYPE string
      RETURNING VALUE(rv_value) TYPE string.
ENDCLASS.

CLASS zcl_material_api_client IMPLEMENTATION.
  METHOD submit.
    DATA lo_destination TYPE REF TO if_http_destination.
    DATA lo_client TYPE REF TO if_web_http_client.
    DATA lo_request TYPE REF TO if_web_http_request.
    DATA lo_response TYPE REF TO if_web_http_response.
    DATA lv_uri TYPE string.
    DATA lv_body TYPE string.
    DATA lv_csrf_token TYPE string.
    DATA lv_status TYPE i.

    TRY.
        lo_destination = cl_http_destination_provider=>create_by_cloud_destination(
          i_name = c_destination
          i_authn_mode = if_a4c_cp_service=>service_specific ).
        lo_client = cl_web_http_client_manager=>create_by_http_destination(
          lo_destination ).
        lo_request = lo_client->get_http_request( ).

        lo_request->set_uri_path( c_service_path ).
        lo_request->set_header_field( i_name = 'x-csrf-token' i_value = 'fetch' ).
        lo_response = lo_client->execute( if_web_http_client=>get ).
        lv_csrf_token = lo_response->get_header_field( 'x-csrf-token' ).

        IF is_payload-action = 'CREATE'.
          lv_uri = |{ c_service_path }/A_Material|.
        ELSE.
          lv_uri = |{ c_service_path }/A_Material('{ zcl_material_api_client=>json_escape( is_payload-material ) }')|.
        ENDIF.

        lv_body = |\{"MaterialType":"{ zcl_material_api_client=>json_escape( is_payload-material_type ) }",| &&
          |"IndustrySector":"{ zcl_material_api_client=>json_escape( is_payload-industry_sector ) }",| &&
          |"BaseUnit":"{ zcl_material_api_client=>json_escape( is_payload-base_unit ) }",| &&
          |"MaterialDescription":"{ zcl_material_api_client=>json_escape( is_payload-description ) }"\}|.

        lo_request = lo_client->get_http_request( ).
        lo_request->set_uri_path( lv_uri ).
        lo_request->set_header_field( i_name = 'x-csrf-token' i_value = lv_csrf_token ).
        lo_request->set_header_field( i_name = 'content-type' i_value = 'application/json' ).
        lo_request->set_text( lv_body ).

        IF is_payload-action = 'CREATE'.
          lo_response = lo_client->execute( if_web_http_client=>post ).
        ELSE.
          lo_response = lo_client->execute( if_web_http_client=>patch ).
        ENDIF.

        lv_status = lo_response->get_status( ).
        IF lv_status < 200 OR lv_status >= 300.
          rs_result-message = |Material API returned HTTP { lv_status }: { lo_response->get_text( ) }|.
          RETURN.
        ENDIF.

        rs_result-success = abap_true.
        rs_result-message = |Material API request completed with HTTP { lv_status }.|.
        rs_result-external_material = is_payload-material.
      CATCH cx_http_dest_provider_error INTO DATA(lx_destination).
        rs_result-message = |Material API destination error: { lx_destination->get_text( ) }|.
      CATCH cx_web_http_client_error INTO DATA(lx_client).
        rs_result-message = |Material API HTTP error: { lx_client->get_text( ) }|.
    ENDTRY.
  ENDMETHOD.

  METHOD json_escape.
    rv_value = iv_value.
    REPLACE ALL OCCURRENCES OF '\' IN rv_value WITH '\\'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_value WITH '\"'.
  ENDMETHOD.
ENDCLASS.

