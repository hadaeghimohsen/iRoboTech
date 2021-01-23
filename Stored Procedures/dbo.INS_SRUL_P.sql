SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_SRUL_P]
	-- Add the parameters for the stored procedure here
	@SRBT_SERV_FILE_NO BIGINT,
	@SRBT_ROBO_RBID BIGINT,
	@CHAT_ID BIGINT,
	@FILE_PATH NVARCHAR(1000),
	@FILE_ID VARCHAR(250),
	@FILE_TYPE VARCHAR(3),
	@RECV_DATE DATETIME,
	@USSD_CODE VARCHAR(250),
   @FILE_NAME VARCHAR(500)
AS
BEGIN
	INSERT INTO dbo.Service_Robot_Upload
	        ( SRBT_SERV_FILE_NO ,
	          SRBT_ROBO_RBID ,
	          RWNO ,
	          CHAT_ID ,
	          FILE_PATH ,
	          FILE_ID ,
	          FILE_TYPE ,
	          RECV_DATE ,
	          USSD_CODE ,
	          FILE_NAME 
	        )
	VALUES  ( @SRBT_SERV_FILE_NO , -- SRBT_SERV_FILE_NO - bigint
	          @SRBT_ROBO_RBID , -- SRBT_ROBO_RBID - bigint
	          0 , -- RWNO - bigint
	          @CHAT_ID , -- CHAT_ID - bigint
	          @FILE_PATH , -- FILE_PATH - nvarchar(1000)
	          @FILE_ID , -- FILE_ID - varchar(250)
	          @FILE_TYPE , -- FILE_TYPE - varchar(3)
	          @RECV_DATE , -- RECV_DATE - datetime
	          @USSD_CODE , -- USSD_CODE - varchar(250)
	          @FILE_NAME  -- FILE_NAME - varchar(500)
	        );
END
GO
