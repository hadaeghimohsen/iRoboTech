SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [dbo].[UPD_APBS_P]
   @Code BIGINT,
   @Titl_Desc NVARCHAR(250),
   @Enty_Name VARCHAR(250),
   @Ref_Code BIGINT,
   @Rwno INT
AS 
BEGIN
   MERGE dbo.App_Base_Define T
   USING (SELECT @Code AS Code, @Titl_Desc AS Titl_Desc, @Enty_Name AS Enty_Name, @Ref_Code AS Ref_Code, @Rwno AS Rwno) S
   ON (T.Code = S.Code)
   WHEN MATCHED THEN
      UPDATE SET
         T.TITL_DESC = S.Titl_Desc,
         T.ENTY_NAME = S.Enty_Name,
         T.REF_CODE = S.Ref_Code,
         T.RWNO = S.Rwno;
END 
GO
