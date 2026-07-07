class ZCL_MM_561 definition
  public
  create public .

public section.

 interfaces IF_HTTP_SERVICE_EXTENSION .
  TYPES : BEGIN OF ty,

              MATERIAL               TYPE i_product-Product,
              PLANT                  TYPE string,
              QUAINTITY              TYPE string,
              STORAGELOCATION        TYPE string,
              BATCH                  TYPE string,
              AMOUNT                 TYPE string,
              WBS                    TYPE string,
              BEAN                   TYPE string,
              postingdate            TYPE string,
              EWMWarehouse           TYPE string,
              BatchBySupplier        TYPE string,

            END OF ty.
 class-DATA : TAB1  TYPE TABLE OF TY .
      TYPES : BEGIN OF ty1,
              MyFirst_Table LIKE TAB1,
              END OF ty1.

CLASS-DATA RESPO TYPE TY1 .
 CLASS-METHODS :
     Post_migo
      IMPORTING VALUE(json)  TYPE string OPTIONAL
      RETURNING VALUE(resp1) TYPE string,
      gET_ERROR
       IMPORTING VALUE(JSON)   TYPE string OPTIONAL
      RETURNING VALUE(ERROR_DESC) TYPE string,
      CreateDOCUMENT
       IMPORTING VALUE(JSON)   TYPE string OPTIONAL
      RETURNING VALUE(MAterialdocument) TYPE string,
       get_mat

        IMPORTING VALUE(mat)      TYPE i_product-Product
        RETURNING VALUE(material) TYPE char18.
protected section.
private section.
ENDCLASS.



CLASS ZCL_MM_561 IMPLEMENTATION.


     METHOD CreateDOCUMENT.
   DATA lv TYPE string.
    FIELD-SYMBOLS <data>  TYPE data.
    FIELD-SYMBOLS <field> TYPE any.
    DATA(lr_d1) = /ui2/cl_json=>generate( json = json ).
    IF lr_d1 IS  BOUND .
    ASSIGN lr_d1->* TO <data>.
    ASSIGN COMPONENT `D` OF STRUCTURE <data> TO <field>.
    IF sy-subrc = 0.
      ASSIGN <field>->* TO <data>.
      ASSIGN COMPONENT `MATERIALDOCUMENT` OF STRUCTURE <data> TO <field>.
      IF sy-subrc = 0.
        ASSIGN <field>->* TO <data>.
        IF sy-subrc = 0.
          ASSIGN COMPONENT `VALUE` OF STRUCTURE <data> TO <field>.
          ASSIGN <field>->* TO <data>.
        ENDIF.
      ENDIF.
    ENDIF.
     MAterialdocument  =   <data> .
    ENDIF .

  ENDMETHOD.


   METHOD get_error.
    DATA lv TYPE string.
    FIELD-SYMBOLS <data>  TYPE data.
    FIELD-SYMBOLS <field> TYPE any.
    DATA(lr_d1) = /ui2/cl_json=>generate( json = json ).

    IF lr_d1 IS  BOUND .
    ASSIGN lr_d1->* TO <data>.
    ASSIGN COMPONENT `ERROR` OF STRUCTURE <data> TO <field>.
     IF sy-subrc = 0.
      ASSIGN <field>->* TO <data>.
      ASSIGN COMPONENT `INNERERROR` OF STRUCTURE <data> TO <field>.
      IF sy-subrc = 0.
      ASSIGN <field>->* TO <data>.
      IF sy-subrc = 0.
      ASSIGN COMPONENT `ERRORDETAILS` OF STRUCTURE <data> TO <field>.
      IF sy-subrc = 0.
      ASSIGN <field>->* TO <data>.
      LOOP AT <data> ASSIGNING FIELD-SYMBOL(<fs>).
      ASSIGN <fs>->* TO FIELD-SYMBOL(<fs1>) .
      ASSIGN COMPONENT `MESSAGE` OF STRUCTURE <fs1> TO <field>    .
      IF sy-subrc = 0.
      ASSIGN COMPONENT `VALUE` OF STRUCTURE <data> TO <field>.
      ASSIGN <field>->* TO <data>.
      DATA ERRORMSJ TYPE STRING.
      ERRORMSJ = ERRORMSJ && cl_abap_char_utilities=>cr_lf && <data> .
      ENDIF.
      ENDLOOP.
      ENDIF.
      ENDIF.
      ENDIF.
      ENDIF.

      IF ERRORMSJ IS INITIAL .
      IF lr_d1 IS  BOUND .
      ASSIGN lr_d1->* TO <data>.
      ASSIGN COMPONENT `ERROR` OF STRUCTURE <data> TO <field>.
      IF sy-subrc = 0.
      ASSIGN <field>->* TO <data>.
      ASSIGN COMPONENT `MESSAGE` OF STRUCTURE <data> TO <field>.
      IF sy-subrc = 0.
      ASSIGN <field>->* TO <data>.
      IF sy-subrc = 0.
      ASSIGN COMPONENT `VALUE` OF STRUCTURE <data> TO <field>.
      ASSIGN <field>->* TO <data>.
      ERRORMSJ  =  <data>.
      ENDIF.
      ENDIF.
      ENDIF.
      ENDIF.
      ENDIF.

      ERROR_DESC  =   ERRORMSJ .
      ENDIF .

  ENDMETHOD.


    METHOD get_mat.
    DATA matnr TYPE char18.
    matnr = |{ mat ALPHA = IN }|.
    material = matnr.
  ENDMETHOD.


  method IF_HTTP_SERVICE_EXTENSION~HANDLE_REQUEST.

   DATA(req) = request->get_form_fields(  ).
   DATA(body)  = request->get_text(  )  .

   xco_cp_json=>data->from_string( body )->write_to( REF #( respo ) ).

   READ TABLE respo-myfirst_table INTO DATA(HEAD) INDEX 1.

    DATA(rb) = '{'.
    DATA(lb) = '}'.
    DATA(RbCON) = '['.
    DATA(LbCON) = ']'.
    DATA fin_json TYPE STRING.

   SELECT FROM @respo-myfirst_table as a
FIELDS COUNT( * ) INTO @data(COUNTLINE).

DATA POSDATE TYPE STRING.

POSDATE =  HEAD-postingdate+0(4) && '-' && HEAD-postingdate+4(2) && '-' && HEAD-postingdate+6(2) && 'T00:00:00'.

  fin_json = fin_json &&
  | { rb } | &
  |"DocumentDate": "{ POSDATE }",| &
  |"PostingDate": "{ POSDATE }",| &
  |"MaterialDocumentHeaderText": "{ '561 Stock' }",| &
  |"CtrlPostgForExtWhseMgmtSyst": "{ '3' }",| &
  |"GoodsMovementCode": "{ '05' }",| &
  |"to_MaterialDocumentItem": { RbCON } | .

  DATA N TYPE I .
  LOOP AT respo-myfirst_table ASSIGNING FIELD-SYMBOL(<fs2>).

   DATA(mat1) = get_mat( mat = <fs2>-material ) .
   SELECT SINGLE * FROM I_Product WITH PRIVILEGED ACCESS as a WHERE Product = @mat1 INTO @data(unit).

   if unit-BaseUnit = 'ST'  .
    unit-BaseUnit = 'PC'.
   elseif unit-BaseUnit = 'PAK'.
   unit-BaseUnit = 'PAC'.
   elseif unit-BaseUnit = 'BOT'.
   unit-BaseUnit = 'BT'.
   elseif unit-BaseUnit = 'KAN'.
   unit-BaseUnit = 'CAN'.
   ELSEif  unit-BaseUnit = 'ZST' .
   unit-BaseUnit = 'SET'.
   ENDIF.

   N = N + 1 .

       fin_json = fin_json &&
                     | { rb } | &
                     |"Material": "{ get_mat( mat = <fs2>-material ) }",| &
                     |"Plant": "{ <fs2>-plant }",| &
                     |"StorageLocation": "{ <fs2>-storagelocation }",| &
                     |"Batch": "{ <fs2>-batch }",| &
                     |"GoodsMovementType": "{ '561' }",| &
                     |"EntryUnit": "{ unit-BaseUnit }",| &
                     |"QuantityInEntryUnit": "{ <fs2>-quaintity }",| &
                     |"GdsMvtExtAmtInCoCodeCrcy": "{ <fs2>-amount }",| &
                     |"UnloadingPointName": "{ <fs2>-BatchBySupplier }",| &
                 "    |"CompanyCodeCurrency": "{ 'INR' }",| &
                     |"EWMWarehouse": "{ <fs2>-ewmwarehouse }",| .
                     if <fs2>-wbs is NOT INITIAL .
                     fin_json = fin_json &&
                     |"EWMStorageBin": "{ <fs2>-bean }",| .
                     else.
                     fin_json = fin_json &&
                     |"EWMStorageBin": "{ <fs2>-bean }"| .
                    endif.
                     if <fs2>-wbs is NOT INITIAL .
                     fin_json = fin_json &&
                     |"InventorySpecialStockType": "{ 'Q' }",| &
                     |"SpecialStockIdfgWBSElement": "{ <fs2>-wbs  }" | .
                     ENDIF.

                     fin_json = fin_json &&
                     |{ lb } |.

     IF countline <> 1 AND N <> countline .
     fin_json = fin_json &&
     | ,| .
    ENDIF.
    clear:unit,mat1.
    ENDLOOP.

         fin_json = fin_json &&
          | { LbCON } { lb }|.
    CONDENSE fin_json .
   DATA(status561) = post_migo( json = fin_json  ).
   DATA(CHECH311)  =  status561+0(3).
DATA MAT TYPE STRING .
 REPLACE ALL OCCURRENCES OF |{ CHECH311 }|  IN status561 WITH ''.

 response->set_text( status561  ).
  endmethod.


    METHOD post_migo.
    TRY.
        DATA(lv_url) = |https://{ cl_abap_context_info=>get_system_url(  ) }:443/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader|.
        DATA(lo_http_destination) =
             cl_http_destination_provider=>create_by_url( lv_url ).
        DATA(lo_web_http_client1) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination ).
        DATA(lo_web_http_request1) = lo_web_http_client1->get_http_request( ).
        lo_web_http_request1->set_authorization_basic( i_username = 'CU_COM_0104'
                                                       i_password = 'PVmHBeGNeHtkSBnEi2oMTsZsj~upndTtbhEypzGe' ).
        lo_web_http_request1->set_header_field( i_name  = 'X-CSRF-Token'
                                                i_value = 'fetch'  ).
        DATA(lo_web_http_response1) = lo_web_http_client1->execute( if_web_http_client=>get ).
        DATA(lv_response1) = lo_web_http_response1->get_header_fields( ).
        DATA(lv_COOKIE) = lo_web_http_response1->get_cookies( ).
        DATA(token) = VALUE #( lv_response1[ name = 'x-csrf-token' ]-value OPTIONAL ).

        " Create Http destination by url; API Endpoint for API Sandbox
        DATA(lo_http_destination1) =
             cl_http_destination_provider=>create_by_url( lv_url ).
        " create HTTP client by destination
        DATA(lo_web_http_client) = cl_web_http_client_manager=>create_by_http_destination( lo_http_destination1 ).
        " Adding headers
        DATA(lo_web_http_request) = lo_web_http_client->get_http_request( ).
        lo_web_http_request->set_authorization_basic( i_username = 'CU_COM_0104'
                                                      i_password = 'PVmHBeGNeHtkSBnEi2oMTsZsj~upndTtbhEypzGe' ).
        lo_web_http_request->set_header_fields( VALUE #( (  name = 'x-csrf-token' value = token )
                                                         (  name = 'DataServiceVersion' value = '2.0' )
                                                         (  name = 'Accept' value = 'application/json' )
                                                         (  name = 'Content-Type' value = 'application/json' ) ) ).
        DATA(cookie11) = lv_COOKIE[ 1 ].
        lo_web_http_request->set_cookie( i_domain  = cookie11-domain
                                         i_expires = cookie11-expires
                                         i_name    = cookie11-name
                                         i_path    = cookie11-path
                                         i_secure  = cookie11-secure
                                         i_value   = cookie11-value  ).
        CONDENSE json.
        lo_web_http_request->set_text( json ).
        " set request method and execute request
        DATA(lo_web_http_response) = lo_web_http_client->execute( if_web_http_client=>post ).
        data(status)   =  lo_web_http_response->get_status( ) .
        data(Error1)   =  lo_web_http_response->get_text( ) .
        IF status-code = '201'.
          resp1 =  |{ status-code } { createdocument( json =  lo_web_http_response->get_text( ) )  } |.
         "  resp1 =  |201  Created Successfully|  .
        ELSE.
          resp1 =  |{ status-code }{ 'Error' } { get_error( json =  lo_web_http_response->get_text( ) )  } |.
        ENDIF.

      CATCH cx_http_dest_provider_error cx_web_http_client_error cx_web_message_error.
        " error handling
    ENDTRY.
   ENDMETHOD.
ENDCLASS.
