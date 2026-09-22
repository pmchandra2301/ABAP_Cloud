# Material RAP inbound-payload sample

This sample demonstrates a small RAP request application for creating or updating
materials from an inbound payload. It is intentionally a staging/request model:
the RAP BO persists the request and its processing result, while a custom action
delegates material persistence to SAP's released **Material OData API**
`API_MATERIAL_SRV`.

The sample is suitable as a starting point for an ABAP Cloud system. It does not
silently claim that a classic material BAPI is released for ABAP Cloud. The
integration uses an HTTP destination and the released ABAP Cloud HTTP client
interfaces instead:

* Destination: `SAP_MATERIAL_API` (create this in the communication arrangement
  for the Material Integration / `API_MATERIAL_SRV` service).
* Service: `/sap/opu/odata/sap/API_MATERIAL_SRV`
* Create: `POST A_Material`
* Update: `PATCH A_Material('<Material>')`

The exact service URL, authentication, client, and supported fields are system
configuration concerns. Adapt the constants in
`ZCL_MATERIAL_API_CLIENT.clas.abap` to the API version exposed by the target
system. If the target is a private/on-premise ABAP system where a released
material BAPI is available, replace only this client class with the approved
destination/RFC adapter; do not call an unreleased BAPI from the RAP behavior.

## Artifacts

| Artifact | Purpose |
| --- | --- |
| `ZT_MAT_REQ.tabl.ddl` | Request/staging persistence |
| `ZI_MaterialPayload.ddls.asddls` | Abstract action parameter and inbound contract |
| `ZI_MaterialRequest.ddls.asddls` | Interface/root CDS view |
| `ZC_MaterialRequest.ddls.asddls` | Consumption projection |
| `ZI_MaterialRequest.bdef.asbdef` | Managed RAP behavior, validation, and action |
| `ZC_MaterialRequest.bdef.asbdef` | Projection behavior exposure |
| `ZUI_MaterialRequest.srvd.srvdsrv` | OData service definition |
| `ZBP_I_MATERIALREQUEST.clas.abap` | Validation and action implementation |
| `ZCL_MATERIAL_API_CLIENT.clas.abap` | Released HTTP integration seam |
| `ZI_MaterialRequest.dcl.asddls` | Instance authorization example |

The names use a `Z` namespace because this repository has no existing package
or namespace convention. Move the objects into a customer package and adjust
the names before activation.

## Inbound payload

The action `SubmitPayload` accepts the following payload:

```json
{
  "material": "MAT-1001",
  "materialType": "ROH",
  "industrySector": "M",
  "baseUnit": "EA",
  "description": "Demo raw material",
  "action": "CREATE"
}
```

`material` is optional for `CREATE` and required for `UPDATE`. For create, the
external API may assign a material number. This compact sample stores the
supplied material key in `ExternalMaterial`; production code should parse the
API response and store the assigned number when numbering is external. `action`
is restricted to `CREATE` or `UPDATE`.

## Transaction flow

1. A caller creates a request row through the RAP BO.
2. The caller invokes `SubmitPayload` with the inbound payload.
3. The behavior handler validates required fields and rejects invalid requests
   through `failed`/`reported`.
4. `ZCL_MATERIAL_API_CLIENT` obtains the configured HTTP destination, fetches a
   CSRF token, and sends `POST` or `PATCH` to `API_MATERIAL_SRV`.
5. A non-2xx response is surfaced as a RAP action error; no success status is
   written.
6. On success, the request row is updated in the same RAP LUW with status
   `SUCCESS`, the returned material number (when available), and a message.
7. The caller commits the RAP transaction according to its normal RAP/OData
   request handling. The external API call is not part of the local database
   transaction; retries and reconciliation should therefore be added for a
   production process.

The client deliberately sends only fields represented by this sample. Material
master creation commonly requires additional plant, sales, valuation, or
storage-location data. Add those fields to the abstract entity and map them in
the client only after checking the target API metadata and authorization.

## Authorization, locking, and validation

* `authorization master ( instance )` and `ZI_MaterialRequest.dcl.asddls`
  illustrate instance authorization. Replace the placeholder authorization
  object/role mapping with the project's actual authorization design.
* `lock master` prevents concurrent updates to one request while the action is
  running.
* `validateRequest` checks action-independent request fields on save.
* `SubmitPayload` checks the action payload and refuses a second submission of a
  successful request.
* HTTP failures and destination/configuration failures are returned as explicit
  RAP messages. They are not converted into a success-shaped fallback.

## Activation and adaptation checklist

1. Create the DDIC/CDS objects in an ABAP Cloud package and activate the table,
   CDS entities, behavior definitions, behavior pool, and DCL in dependency
   order.
2. Create a communication arrangement and destination named
   `SAP_MATERIAL_API`, exposing the released Material OData API.
3. Verify the API metadata, especially material numbering and update key syntax.
4. Replace the example DCL condition with the application's authorization
   object and assign the corresponding business role.
5. Add an OData V4 service definition/service binding if the sample is exposed
   externally.
6. Add ABAP Unit tests using a test seam or HTTP client double before enabling
   unattended processing. This repository contains no ABAP test runner, so no
   executable tests are included here.
