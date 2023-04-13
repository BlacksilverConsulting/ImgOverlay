SELECT
  ugr_GroupNum
FROM
  img_UnkGroup
WHERE
  ugr_Divison = ANY( ?::TEXT[] )
ORDER BY
  ugr_Division,
  ugr_GroupNum
;
