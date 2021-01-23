SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [dbo].[INS_APBS_P]
   @Titl_Desc NVARCHAR(250),
   @Enty_Name VARCHAR(250),
   @Ref_Code BIGINT,
   @Rwno INT
AS 
BEGIN
   MERGE dbo.App_Base_Define T
   USING (SELECT @Titl_Desc AS Titl_Desc, @Enty_Name AS Enty_Name, @Ref_Code AS Ref_Code) S
   ON (T.TITL_DESC = S.Titl_Desc AND 
       T.ENTY_NAME = S.Enty_Name AND
       T.REF_CODE = S.Ref_Code)
   WHEN NOT MATCHED THEN
      INSERT (code, TITL_DESC, ENTY_NAME, REF_CODE, RWNO)
      VALUES (0, s.Titl_Desc, s.Enty_Name, s.Ref_Code, @Rwno);
         
END 
GO
