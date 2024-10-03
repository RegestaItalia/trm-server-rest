CLASS zcl_trm_rest_resource DEFINITION
  PUBLIC
  INHERITING FROM cl_rest_resource
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor.
    METHODS if_rest_resource~get REDEFINITION.
    METHODS if_rest_resource~post REDEFINITION.
    METHODS if_rest_resource~put REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS handle_request.
    METHODS get_request_json
      RETURNING VALUE(rv_json) TYPE string.

    METHODS add_lang_tr
      EXPORTING ev_status TYPE i
                ev_reason TYPE string
      RAISING   zcx_trm_exception.
ENDCLASS.



CLASS zcl_trm_rest_resource IMPLEMENTATION.

  METHOD constructor.
    super->constructor( ).
  ENDMETHOD.

  METHOD if_rest_resource~get.
    handle_request( ).
  ENDMETHOD.

  METHOD if_rest_resource~post.
    handle_request( ).
  ENDMETHOD.

  METHOD if_rest_resource~put.
    handle_request( ).
  ENDMETHOD.

  METHOD handle_request.
    DATA: lv_method        TYPE seocpdname,
          lv_status        TYPE i,
          lv_reason        TYPE string,
          lo_trm_exception TYPE REF TO zcx_trm_exception,
          lo_response      TYPE REF TO if_rest_entity,
          ls_message       TYPE symsg.
    lv_method = mo_request->get_uri_attribute( iv_name = 'METH' ).
    CONDENSE lv_method.
    TRANSLATE lv_method TO UPPER CASE.
    TRY.
        CALL METHOD me->(lv_method)
          IMPORTING
            ev_status = lv_status
            ev_reason = lv_reason.
        IF lv_status IS INITIAL.
          lv_status = cl_rest_status_code=>gc_success_ok.
        ENDIF.
      CATCH zcx_trm_exception INTO lo_trm_exception.
        lv_status = cl_rest_status_code=>gc_server_error_internal.
        lv_reason = lo_trm_exception->reason( ).
      CATCH cx_root.
        lv_status = cl_rest_status_code=>gc_server_error_internal.
        lv_reason = 'Method call exception'.
    ENDTRY.
    IF lv_status <> cl_rest_status_code=>gc_success_ok AND sy-subrc <> 0.
      lo_response = mo_response->create_entity( ).
      lo_response->set_content_type( iv_media_type = if_rest_media_type=>gc_appl_json ).
      MOVE-CORRESPONDING sy TO ls_message.
      lo_response->set_string_data( /ui2/cl_json=>serialize( ls_message ) ).
    ENDIF.
    mo_response->set_status( lv_status ).
    mo_response->set_reason( lv_reason ).
  ENDMETHOD.

  METHOD get_request_json.
    rv_json = mo_request->get_entity( )->get_string_data( ).
  ENDMETHOD.

  METHOD add_lang_tr.
    TYPES: BEGIN OF ty_request,
             trkorr   TYPE trkorr,
             devclass TYPE lxe_tt_packg,
           END OF ty_request.
    DATA: lo_transport    TYPE REF TO zcl_trm_transport,
          lv_request_json TYPE string,
          ls_request      TYPE ty_request.

    IF mo_request->get_method( ) <> if_rest_message=>gc_method_put.
      ev_status = cl_rest_status_code=>gc_client_error_meth_not_allwd.
      RETURN.
    ENDIF.

    lv_request_json = get_request_json( ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_json CHANGING data = ls_request ).

    CREATE OBJECT lo_transport EXPORTING iv_trkorr = ls_request-trkorr.
    lo_transport->add_translations(
      EXPORTING
        it_devclass = ls_request-devclass
    ).
  ENDMETHOD.

ENDCLASS.
