@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Material inbound request'
define root view entity ZI_MaterialRequest
  as select from zt_mat_req
{
  key request_uuid       as RequestUUID,
      material           as Material,
      material_type      as MaterialType,
      industry_sector    as IndustrySector,
      base_unit          as BaseUnit,
      description        as Description,
      status             as Status,
      external_material  as ExternalMaterial,
      message            as Message,
      created_by         as CreatedBy,
      created_at         as CreatedAt,
      last_changed_by    as LastChangedBy,
      last_changed_at    as LastChangedAt,
      local_last_changed as LocalLastChanged
}

