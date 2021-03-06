USE [DB_A2CB54_11]
GO
/****** Object:  StoredProcedure [dbo].[webAPI_Admin_GetAllSportWithRelations]    Script Date: 12/8/2017 9:20:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[webAPI_Admin_GetAllSportWithRelations]
AS
BEGIN
	SELECT 
		DISTINCT
		S.Id as SportId,
		S.Name as SportName,
		L.Id as LeagueId,
		L.Name as LeagueName,
		C.Code as CountryCode,
		C.Name as CountryName,
		T.Id as TeamId,
		T.Name as TeamName
	FROM League L
		INNER JOIN dbo.Sport S WITH(NOLOCK) ON S.Id = L.SportId
		INNER JOIN dbo.Country C WITH(NOLOCK) ON C.code = L.CountryCode
		LEFT JOIN dbo.Team T WITH(NOLOCK) ON T.SportId = S.Id
	WHERE 1=1
		AND L.Status = 1
END