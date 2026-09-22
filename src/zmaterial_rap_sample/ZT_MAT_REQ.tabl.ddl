@EndUserText.label : 'Material inbound request'
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
define table zt_mat_req {
  key client              : abap.clnt not null;
  key request_uuid        : sysuuid_x16 not null;
      material            : abap.char(40);
      material_type       : abap.char(4) not null;
      industry_sector     : abap.char(1) not null;
      base_unit           : abap.unit(3);
      description         : abap.char(40);
      status              : abap.char(10) not null;
      external_material   : abap.char(40);
      message             : abap.char(220);
      created_by          : abp_creation_user;
      created_at          : abp_creation_tstmpl;
      last_changed_by     : abp_lastchange_user;
      last_changed_at     : abp_lastchange_tstmpl;
      local_last_changed  : abp_locinst_lastchange_tstmpl;
}

