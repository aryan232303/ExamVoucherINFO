create database voucherdatabase;
use voucherdatabase;

CREATE TABLE Roles ( RoleID INT IDENTITY(1,1) PRIMARY KEY, RoleName VARCHAR(50) NOT NULL UNIQUE, Description VARCHAR(200) NULL );

CREATE TABLE Users ( UserID INT IDENTITY(1,1) PRIMARY KEY, EmployeeID VARCHAR(20) NOT NULL UNIQUE, FullName NVARCHAR(100) NOT NULL, Email VARCHAR(150) NOT NULL UNIQUE, PasswordHash VARCHAR(255) NOT NULL, RoleID INT NOT NULL REFERENCES Roles(RoleID), ManagerID INT NULL REFERENCES Users(UserID), Department VARCHAR(100) NULL, IsActive BIT NOT NULL DEFAULT 1, CreatedAt DATETIME NOT NULL DEFAULT GETDATE(), UpdatedAt DATETIME NULL );

CREATE TABLE UserSessions ( SessionID INT IDENTITY(1,1) PRIMARY KEY, UserID INT NOT NULL REFERENCES Users(UserID), SessionToken VARCHAR(500) NOT NULL UNIQUE, LoginTime DATETIME NOT NULL DEFAULT GETDATE(), LastActivityTime DATETIME NOT NULL DEFAULT GETDATE(), LogoutTime DATETIME NULL, IsActive BIT NOT NULL DEFAULT 1, IPAddress VARCHAR(50) NULL, TimeoutMinutes INT NOT NULL DEFAULT 30 );

CREATE TABLE Certifications ( CertificationID INT IDENTITY(1,1) PRIMARY KEY, CertName NVARCHAR(150) NOT NULL, Provider VARCHAR(100) NULL, ExamCode VARCHAR(50) NULL, ValidityMonths INT NULL, IsActive BIT NOT NULL DEFAULT 1 );

CREATE TABLE Vouchers ( VoucherID INT IDENTITY(1,1) PRIMARY KEY, VoucherCode VARCHAR(100) NOT NULL UNIQUE, CertificationID INT NOT NULL REFERENCES Certifications(CertificationID), ExpiryDate DATE NOT NULL, Status VARCHAR(20) NOT NULL DEFAULT 'Available' CHECK (Status IN ('Available','Allocated','Used','Expired')), UploadedBy INT NULL REFERENCES Users(UserID), UploadedAt DATETIME NOT NULL DEFAULT GETDATE() );

CREATE TABLE VoucherRequests ( RequestID INT IDENTITY(1,1) PRIMARY KEY, EmployeeID INT NOT NULL REFERENCES Users(UserID), CertificationID INT NOT NULL REFERENCES Certifications(CertificationID), VoucherID INT NULL REFERENCES Vouchers(VoucherID), Status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (Status IN ('Pending','Approved','Rejected','Cancelled','Used')), RequestDate DATETIME NOT NULL DEFAULT GETDATE(), ReviewedBy INT NULL REFERENCES Users(UserID), ReviewedAt DATETIME NULL, ManagerComment NVARCHAR(500) NULL, UsageConfirmedAt DATETIME NULL, CertificationDetails NVARCHAR(500) NULL);

CREATE TABLE MonthlyRequestLimits ( LimitID INT IDENTITY(1,1) PRIMARY KEY, RoleID INT NOT NULL REFERENCES Roles(RoleID), MaxPerMonth INT NOT NULL DEFAULT 2, EffectiveFrom DATE NOT NULL DEFAULT GETDATE() );

CREATE TABLE Notifications ( NotificationID INT IDENTITY(1,1) PRIMARY KEY, RecipientUserID INT NOT NULL REFERENCES Users(UserID), Subject NVARCHAR(200) NOT NULL, Message NVARCHAR(1000) NOT NULL, IsRead BIT NOT NULL DEFAULT 0, CreatedAt DATETIME NOT NULL DEFAULT GETDATE(), RelatedRequestID INT NULL REFERENCES VoucherRequests(RequestID) );

CREATE TABLE AuditLog ( LogID INT IDENTITY(1,1) PRIMARY KEY, UserID INT NULL REFERENCES Users(UserID), Action VARCHAR(100) NOT NULL, TableName VARCHAR(100) NULL, RecordID INT NULL, OldValue NVARCHAR(MAX) NULL, NewValue NVARCHAR(MAX) NULL, LoggedAt DATETIME NOT NULL DEFAULT GETDATE(), IPAddress VARCHAR(50) NULL );

GO

INSERT INTO Roles (RoleName, Description) VALUES ('Admin', 'Full system access including bulk operations'), ('Manager', 'Approve/reject requests and view team dashboard'), ('Employee', 'Submit and track voucher requests'), ('System', 'Automated system operations');

INSERT INTO Users (EmployeeID, FullName, Email, PasswordHash, RoleID, ManagerID, Department) VALUES ('ADM001', 'Alice Admin', 'alice@company.com', '$2b$12$adminHash1', 1, NULL, 'IT'), ('MGR001', 'Bob Manager', 'bob@company.com', '$2b$12$mgrHash1', 2, NULL, 'Engineering'), ('MGR002', 'Carol Manager', 'carol@company.com', '$2b$12$mgrHash2', 2, NULL, 'Finance'), ('EMP001', 'David Employee', 'david@company.com', '$2b$12$empHash1', 3, 2, 'Engineering'), ('EMP002', 'Eva Employee', 'eva@company.com', '$2b$12$empHash2', 3, 2, 'Engineering'), ('EMP003', 'Frank Employee', 'frank@company.com', '$2b$12$empHash3', 3, 3, 'Finance'), ('EMP004', 'Grace Employee', 'grace@company.com', '$2b$12$empHash4', 3, 2, 'Engineering'), ('EMP005', 'Henry Employee', 'henry@company.com', '$2b$12$empHash5', 3, 3, 'Finance');

INSERT INTO Certifications (CertName, Provider, ExamCode, ValidityMonths) VALUES ('AWS Solutions Architect Associate', 'Amazon', 'SAA-C03', 36), ('Azure Fundamentals', 'Microsoft', 'AZ-900', 24), ('Google Cloud Associate', 'Google', 'GCP-ACE', 24), ('CKAD - Kubernetes Dev', 'CNCF', 'CKAD', 24), ('CompTIA Security+', 'CompTIA', 'SY0-701', 36), ('Scrum Master (PSM I)', 'Scrum.org', 'PSM-I', NULL);

INSERT INTO Vouchers (VoucherCode, CertificationID, ExpiryDate, Status, UploadedBy) VALUES ('AWS-VCHR-0001', 1, '2025-12-31', 'Available', 1), ('AWS-VCHR-0002', 1, '2025-12-31', 'Available', 1), ('AWS-VCHR-0003', 1, '2025-06-30', 'Available', 1), ('AZ-VCHR-0001', 2, '2025-11-30', 'Available', 1), ('AZ-VCHR-0002', 2, '2025-11-30', 'Allocated', 1), ('GCP-VCHR-0001', 3, '2025-09-30', 'Available', 1), ('CKAD-VCHR-001', 4, '2026-01-31', 'Available', 1), ('SEC-VCHR-0001', 5, '2025-08-31', 'Used', 1), ('PSM-VCHR-0001', 6, '2025-10-31', 'Available', 1), ('PSM-VCHR-0002', 6, '2025-10-31', 'Available', 1);

INSERT INTO MonthlyRequestLimits (RoleID, MaxPerMonth) VALUES (3, 2);

INSERT INTO VoucherRequests (EmployeeID, CertificationID, VoucherID, Status, RequestDate, ReviewedBy, ReviewedAt, ManagerComment, UsageConfirmedAt, CertificationDetails) VALUES (4, 1, 5, 'Used', '2025-01-10', 2, '2025-01-11', NULL, '2025-02-01', 'Plan to take exam Feb 2025'), (5, 2, 5, 'Approved', '2025-03-05', 2, '2025-03-06', NULL, NULL, 'Azure exam scheduled'), (4, 3, NULL, 'Pending', '2025-04-01', NULL, NULL, NULL, NULL, 'Need GCP cert for project'), (6, 1, NULL, 'Rejected','2025-02-15', 3, '2025-02-16', 'Already claimed AWS voucher this quarter', NULL, 'AWS cert needed'), (7, 4, NULL, 'Cancelled','2025-03-20',NULL, NULL, NULL, NULL, 'Changed project assignment'), (8, 5, NULL, 'Pending', '2025-04-02', NULL, NULL, NULL, NULL, 'Security+ for compliance role');

INSERT INTO Notifications (RecipientUserID, Subject, Message, RelatedRequestID) VALUES (2, 'New Voucher Request', 'David Employee has submitted a new voucher request for GCP.', 3), (2, 'Pending Approval Reminder','You have 1 pending voucher request awaiting review.', 3), (3, 'New Voucher Request', 'Henry Employee has submitted a new voucher request for Security+.', 6), (6, 'Request Rejected', 'Your AWS voucher request was rejected. Reason: Already claimed this quarter.', 4), (4, 'Request Approved', 'Your Azure voucher request has been approved!', 2);

INSERT INTO UserSessions (UserID, SessionToken, LoginTime, LastActivityTime, IsActive, IPAddress) VALUES (4, 'tok_emp001_abc123', DATEADD(MINUTE,-20,GETDATE()), DATEADD(MINUTE,-5,GETDATE()), 1, '192.168.1.10'), (2, 'tok_mgr001_def456', DATEADD(MINUTE,-45,GETDATE()), DATEADD(MINUTE,-35,GETDATE()), 1, '192.168.1.20'), (5, 'tok_emp002_ghi789', DATEADD(HOUR,-2, GETDATE()), DATEADD(HOUR,-2,GETDATE()), 0, '192.168.1.11');
GO

--UDF-04: fn_IsSessionActive
--   Returns 1 if the session token is valid and not timed out
--   Used by: US-15 Session Timeout
CREATE FUNCTION dbo.fn_IsSessionActive
(
    @SessionToken  VARCHAR(500),
    @TimeoutMinutes INT = 30
)
RETURNS BIT
AS
BEGIN
    DECLARE @Active BIT = 0;
    IF EXISTS (
        SELECT 1 FROM UserSessions
WHERE  SessionToken = @SessionToken
          AND  IsActive = 1
          AND  DATEDIFF(MINUTE, LastActivityTime, GETDATE()) < @TimeoutMinutes
    )
        SET @Active = 1;
    RETURN @Active;
END;
GO

-- TVF-01: fn_GetVoucherListWithFilters
--   Returns vouchers with optional filters on cert and status
--   Used by: US-02 Voucher Listing with Filter

CREATE FUNCTION dbo.fn_GetVoucherListWithFilters
(
    @CertificationID INT         = NULL,
    @Status          VARCHAR(20) = NULL,
    @ExpiryFrom      DATE        = NULL,
    @ExpiryTo        DATE        = NULL
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        v.VoucherID,
        v.VoucherCode,
        c.CertName,
        c.Provider,
        c.ExamCode,
        v.ExpiryDate,
        v.Status,
        v.UploadedAt,
        u.FullName AS UploadedByName
    FROM  Vouchers         v
    JOIN  Certifications   c ON v.CertificationID = c.CertificationID
    LEFT  JOIN Users       u ON v.UploadedBy      = u.UserID
    WHERE (@CertificationID IS NULL OR v.CertificationID = @CertificationID)
      AND (@Status          IS NULL OR v.Status          = @Status)
      AND (@ExpiryFrom      IS NULL OR v.ExpiryDate     >= @ExpiryFrom)
      AND (@ExpiryTo        IS NULL OR v.ExpiryDate     <= @ExpiryTo)
);
GO

-- TVF-02: fn_GetEmployeeRequestHistory
--   Returns full request history for one employee
--   Used by: US-11 View Request Status | US-17 View Request History

CREATE FUNCTION dbo.fn_GetEmployeeRequestHistory(
@EmployeeUserID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        vr.RequestID,
        c.CertName,
        c.Provider,
        v.VoucherCode,
        vr.Status,
        vr.RequestDate,
        vr.ReviewedAt,
        vr.ManagerComment,
        vr.UsageConfirmedAt,
        vr.CertificationDetails,
        mgr.FullName AS ReviewedByName
    FROM  VoucherRequests  vr
    JOIN  Certifications   c   ON vr.CertificationID = c.CertificationID
    LEFT  JOIN Vouchers    v   ON vr.VoucherID       = v.VoucherID
    LEFT  JOIN Users       mgr ON vr.ReviewedBy      = mgr.UserID
    WHERE vr.EmployeeID = @EmployeeUserID
);
GO

-- SP-01: usp_AuthenticateUser
-- Validates credentials and creates a session
--   Used by: US-01 Authentication

CREATE PROCEDURE dbo.usp_AuthenticateUser
    @EmployeeID   VARCHAR(20),
    @PasswordHash VARCHAR(255),
    @IPAddress    VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @UserID    INT;
    DECLARE @RoleName  VARCHAR(50);
    DECLARE @Token     VARCHAR(500);
    SELECT  @UserID   = u.UserID,
            @RoleName = r.RoleName
    FROM    Users u
    JOIN    Roles r ON u.RoleID = r.RoleID
    WHERE   u.EmployeeID   = @EmployeeID
      AND   u.PasswordHash = @PasswordHash
      AND   u.IsActive     = 1;
    IF @UserID IS NULL
    BEGIN
        SELECT 'FAILED' AS AuthResult, NULL AS SessionToken, NULL AS RoleName;
        RETURN;
    END
    -- Generate pseudo-token (in production use app-layer UUID)
    SET @Token = CONVERT(VARCHAR(500),
                     HASHBYTES('SHA2_256', @EmployeeID + CAST(NEWID() AS VARCHAR(50))), 2);
    INSERT INTO UserSessions (UserID, SessionToken, IPAddress)
    VALUES (@UserID, @Token, @IPAddress);
    INSERT INTO AuditLog (UserID, Action, TableName, RecordID)
    VALUES (@UserID, 'LOGIN', 'UserSessions', SCOPE_IDENTITY());
    SELECT 'SUCCESS' AS AuthResult, @Token AS SessionToken, @RoleName AS RoleName, @UserID AS
UserID;
END;
GO

-- SP-02: usp_ValidateEmployeeID
--   Checks whether an employee code is valid and active
--   Used by: US-03 Employee ID Validation

CREATE PROCEDURE dbo.usp_ValidateEmployeeID
@EmployeeCode VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        u.UserID,
        u.EmployeeID,
        u.FullName,
        u.Email,
        u.Department,
        r.RoleName,
        dbo.fn_IsEmployeeIDValid(@EmployeeCode) AS IsValid
    FROM  Users u
    JOIN  Roles r ON u.RoleID = r.RoleID
    WHERE u.EmployeeID = @EmployeeCode;
END;
GO