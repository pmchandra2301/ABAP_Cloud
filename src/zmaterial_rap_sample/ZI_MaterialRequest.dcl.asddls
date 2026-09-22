@EndUserText.label: 'Material request instance authorization'
@MappingRole: true
define role ZR_MATERIALREQUEST {
  grant
    select
      on
        ZI_MaterialRequest
          where ( CreatedBy = $session.user );
}

