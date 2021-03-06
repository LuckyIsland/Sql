USE [DB_A2CB54_11]
GO
/****** Object:  StoredProcedure [dbo].[webAPI_Admin_GetAllSportWithBetTypes]    Script Date: 12/8/2017 9:20:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[webAPI_Admin_GetAllSportWithBetTypes]
AS
BEGIN
	SELECT 
		DISTINCT
		S.Id as SportId,
		S.Name as SportName,
		BT.Id as BetTypeId,
		BT.Name as BetTypeName,
		BGT.Id as OddId,
		BGT.Title as OddTitle,
		BGT.IsOddPoint as IsOddPoint
	FROM Sport S
		INNER JOIN dbo.BaseSportBetTypes BSBT WITH(NOLOCK) ON S.Id = BSBT.SportId
		INNER JOIN dbo.BetType BT WITH(NOLOCK) ON BT.Id = BSBT.BetTypeId
		LEFT JOIN dbo.BetGroupType BGT WITH(NOLOCK) ON BT.Id = BGT.BetTypeId
	WHERE 1=1
END