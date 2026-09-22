CLASS lhc_materialrequest DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS validateRequest FOR VALIDATE ON SAVE
      IMPORTING keys FOR MaterialRequest~validateRequest.
    METHODS submitPayload FOR MODIFY
      IMPORTING keys FOR ACTION MaterialRequest~SubmitPayload RESULT result.
ENDCLASS.

CLASS lhc_materialrequest IMPLEMENTATION.
  METHOD validateRequest.
    READ ENTITIES OF ZI_MaterialRequest IN LOCAL MODE
      ENTITY MaterialRequest
      FIELDS ( MaterialType IndustrySector BaseUnit Description Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    LOOP AT lt_requests ASSIGNING FIELD-SYMBOL(<request>).
      IF <request>-MaterialType IS INITIAL OR <request>-IndustrySector IS INITIAL
          OR <request>-BaseUnit IS INITIAL OR <request>-Description IS INITIAL.
        APPEND VALUE #( %tky = <request>-%tky ) TO failed-materialrequest.
        APPEND VALUE #(
          %tky = <request>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Material type, industry sector, base unit, and description are required.' )
        ) TO reported-materialrequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD submitPayload.
    READ ENTITIES OF ZI_MaterialRequest IN LOCAL MODE
      ENTITY MaterialRequest
      FIELDS ( Status )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_requests).

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      READ TABLE lt_requests ASSIGNING FIELD-SYMBOL(<request>)
        WITH KEY %tky = <key>-%tky.
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-materialrequest.
        CONTINUE.
      ENDIF.

      IF <request>-Status = 'SUCCESS'.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-materialrequest.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'A successful material request cannot be submitted again.' )
        ) TO reported-materialrequest.
        CONTINUE.
      ENDIF.

      DATA(ls_payload) = VALUE zcl_material_api_client=>ty_payload(
        material        = <key>-%param-material
        material_type   = <key>-%param-materialType
        industry_sector = <key>-%param-industrySector
        base_unit       = <key>-%param-baseUnit
        description     = <key>-%param-description
        action          = <key>-%param-action ).

      IF ls_payload-action <> 'CREATE' AND ls_payload-action <> 'UPDATE'.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-materialrequest.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Action must be CREATE or UPDATE.' )
        ) TO reported-materialrequest.
        CONTINUE.
      ENDIF.

      IF ls_payload-material_type IS INITIAL OR ls_payload-industry_sector IS INITIAL
          OR ls_payload-base_unit IS INITIAL OR ls_payload-description IS INITIAL.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-materialrequest.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Material type, industry sector, base unit, and description are required in the payload.' )
        ) TO reported-materialrequest.
        CONTINUE.
      ENDIF.

      IF ls_payload-action = 'UPDATE' AND ls_payload-material IS INITIAL.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-materialrequest.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Material is required for UPDATE.' )
        ) TO reported-materialrequest.
        CONTINUE.
      ENDIF.

      DATA(ls_api_result) = zcl_material_api_client=>submit( ls_payload ).
      IF ls_api_result-success = abap_false.
        APPEND VALUE #( %tky = <key>-%tky ) TO failed-materialrequest.
        APPEND VALUE #(
          %tky = <key>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = ls_api_result-message )
        ) TO reported-materialrequest.
        CONTINUE.
      ENDIF.

      MODIFY ENTITIES OF ZI_MaterialRequest IN LOCAL MODE
        ENTITY MaterialRequest
        UPDATE FIELDS ( Status ExternalMaterial Message )
        WITH VALUE #( (
          %tky = <key>-%tky
          Status = 'SUCCESS'
          ExternalMaterial = ls_api_result-external_material
          Message = ls_api_result-message ) ).

      APPEND VALUE #( %tky = <key>-%tky ) TO result.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS zbp_i_materialrequest DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF ZI_MaterialRequest.
ENDCLASS.

CLASS zbp_i_materialrequest IMPLEMENTATION.
ENDCLASS.
