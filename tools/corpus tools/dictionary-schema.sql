if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[NewWords]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[NewWords]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[OldWords]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[OldWords]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Words]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[Words]
GO

CREATE TABLE [dbo].[NewWords] (
	[word] [nvarchar] (48) COLLATE SQL_Latin1_General_CP1_CS_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[OldWords] (
	[word] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CS_AS NULL 
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Words] (
	[word] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CS_AS NULL ,
	[wordcount] [int] NULL ,
	[documentcount] [int] NULL ,
	[modernword] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CS_AS NULL 
) ON [PRIMARY]
GO

