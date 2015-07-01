unit mpBackend;

interface

uses
  Windows, SysUtils, ShlObj, ShellApi, Classes, IniFiles, Dialogs, Masks,
  Controls, Registry, DateUtils, Graphics,
  // zeosdbo components
  ZConnection, ZDataset,
  ZDbcCache, ZAbstractRODataset, ZDbcMySQL, ZDbcPostgreSQL, DB, ZSqlUpdate,
  ComCtrls, ZDbcInterbase6, ZSqlMonitor, ZAbstractDataset, ZSequence,
  // abbrevia components
  AbBase, AbBrowse, AbZBrows, AbZipper, AbArcTyp,
  // superobject
  superobject,
  // crc32
  CRC32,
  // mp components
  mpLogger, mpTracker;

type
  TLogMessage = class (TOBject)
  public
    time: string;
    group: string;
    &label: string;
    text: string;
    constructor Create(time, group, &label, text: string); Overload;
  end;
  TUser = class(TObject)
  public
    ip: string;
    username: string;
    auth: string;
    firstSeen: TDateTime;
    lastSeen: TDateTime;
    timesSeen: integer;
    download: Int64;
    upload: Int64;
    timesRun: integer;
    mergesBuilt: integer;
    pluginsChecked: integer;
    pluginsMerged: integer;
    reportsSubmitted: integer;
    constructor Create(ip: string); Overload;
    constructor Create(const fields: TFields); Overload;
  end;
  TBlacklistEntry = class(TObject)
  public
    ip: string;
    username: string;
    created: TDateTime;
    expires: TDateTime;
    constructor Create(ip, username: string; duration: real); Overload;
    constructor Create(const fields: TFields); Overload;
  end;
  TmpMessage = class(TObject)
  public
    id: integer;
    username: string;
    auth: string;
    data: string;
    constructor Create(id: integer; username, auth, data: string); Overload;
    function ToJson: string;
    procedure FromJson(json: string);
  end;
  TmpStatus = class(TObject)
  public
    programVersion: string;
    tes5Hash: string;
    tes4Hash: string;
    fnvHash: string;
    fo3Hash: string;
    function ToJson: string;
    procedure FromJson(json: string);
    procedure Refresh;
  end;
  TReport = class(TObject)
  public
    game: string;
    username: string;
    filename: string;
    hash: string;
    recordCount: integer;
    rating: integer;
    mergeVersion: string;
    notes: TStringList;
    dateSubmitted: TDateTime;
    constructor Create; Overload;
    constructor Create(const fields: TFields); Overload;
    function ToJson: string;
    procedure FromJson(json: string);
  end;
  TEntry = class(TObject)
  public
    filename: string;
    hash: string;
    records: string;
    version: string;
    rating: string;
    reports: string;
    notes: string;
    constructor Create; Overload;
    constructor Create(const s: string); Overload;
    function ToText: string;
  end;
  TSettings = class(TObject)
  public
    simpleLogView: boolean;
    simpleReportsView: boolean;
    simpleDictionaryView: boolean;
    serverMessageColor: TColor;
    initMessageColor: TColor;
    SQLMessageColor: TColor;
    dictionaryMessageColor: TColor;
    javaMessageColor: TColor;
    errorMessageColor: TColor;
    bSeparateHashes: boolean;
    bSeparateRecords: boolean;
    bSeparateVersions: boolean;
    templateHash: string;
    templateNoHash: string;
    constructor Create; Overload;
    procedure Save(const filename: string);
    procedure Load(const filename: string);
  end;
  TStatistics = class(TObject)
  public
    timesRun: integer;
    uniqueIPs: TStringList;
    dictionaryUpdates: integer;
    programUpdates: integer;
    reportsRecieved: integer;
    reportsApproved: integer;
    reportsDenied: integer;
    totalBandwidth: Int64;
    totalUptime: TDateTime;
    tes5Reports: integer;
    tes4Reports: integer;
    fnvReports: integer;
    fo3Reports: integer;
    tes5Logins: integer;
    tes4Logins: integer;
    fnvLogins: integer;
    fo3Logins: integer;
    constructor Create; virtual;
    procedure Save(const filename: string);
    procedure Load(const filename: string);
  end;

  { MySQL methods }
  procedure DoLogin(userID, password, database, host, port: string);
  procedure SQLQuery(query: string);
  //==USERS==
  procedure QueryUsers;
  function UserWhereClause(user: TUser): string;
  function UserSetClause(user: TUser): string;
  function UserValuesClause(user: TUser): string;
  procedure UpdateUser(SetClause, WhereClause: string); Overload;
  procedure AddUser(user: TUser); Overload;
  procedure RemoveUser(user: TUser);
  //==BLACKLIST==
  procedure QueryBlacklist;
  function BlacklistWhereClause(entry: TBlacklistEntry): string;
  function BlacklistSetClause(entry: TBlacklistEntry): string;
  function BlacklistValuesClause(entry: TBlacklistEntry): string;
  procedure UpdateBlacklist(SetClause, WhereClause: string);
  procedure AddBlacklist(entry: TBlacklistEntry);
  procedure RemoveBlacklist(entry: TBlacklistEntry);
  //==REPORTS==
  procedure QueryReports;
  function ReportWhereClause(report: TReport): string;
  function ReportSetClause(report: TReport): string;
  procedure UpdateReport(report: TReport; SetClause, WhereClause: string);
  procedure AddReport(report: TReport; table: string);
  procedure RemoveReport(report: TReport; table: string);
  { General functions }
  function csvText(s: string): string;
  function FormatByteSize(const bytes: Int64): string;
  function DateBuiltString(date: TDateTime): string;
  function DateTimeToSQL(date: TDateTime): string;
  function TimeStr(date: TDateTime): string;
  function AppendIfMissing(str, substr: string): string;
  function StrEndsWith(s1, s2: string): boolean;
  function RemoveFromEnd(s1, s2: string): string;
  function IntegerListSum(list: TList; maxIndex: integer): integer;
  function Wordwrap(var s: string; charCount: integer): string;
  function ContainsMatch(var sl: TStringList; const s: string): boolean;
  function IsURL(s: string): boolean;
  function GetSessionUptime: TDateTime;
  function GetVersionMem: string;
  function FileVersion(const FileName: string): String;
  function ApplyTemplate(const template: string; var map: TStringList): string;
  { Windows API functions }
  function GetCSIDLShellFolder(CSIDLFolder: integer): string;
  function GetFileSize(const aFilename: String): Int64;
  function GetLastModified(const aFileName: String): TDateTime;
  function RecursiveFileSearch(aPath, aFileName: string; ignore: TStringList; maxDepth: integer): string;
  procedure CopyDirectory(src, dst: string; fIgnore, dIgnore: TStringList);
  procedure GetFilesList(path: string; var fIgnore, dIgnore, list: TStringList);
  procedure CopyFiles(src, dst: string; var list: TStringList);
  { Data methods }
  procedure LoadSettings;
  procedure SaveSettings;
  procedure LoadStatistics;
  procedure SaveStatistics;
  procedure EntryNotes(var sl: TStringList; var report: TReport);
  procedure RebuildDictionary(game: string; var lst: TList);
  procedure RebuildDictionaries;
  procedure UpdateRebuildBooleans(report: TReport);
  function GetDictionary(name: string): string;
  function GetDictionaryHash(name: string): string;
  procedure LoadDictionary(var lst: TList; var sl: TStringList; filename: string);
  procedure LoadBlacklist(var lst, dictionary: TList);
  function GetRatingColor(rating: real): integer;
  function GetEntry(var dictionary: TList; pluginName, numRecords, version: string): TEntry;
  procedure SaveLog(var Log: TList);
  function CompareReports(P1, P2: Pointer): Integer;
  { User methods }
  function Authorized(ip, username, auth: string): boolean;
  function ResetAuth(ip, username, auth: string): boolean;
  function GetUser(ip, username, auth: string): TUser; Overload;
  function GetUser(ip: string): TUser; Overload;
  function AddUser(ip: string): TUser; Overload;
  procedure UpdateUser(ip, username, auth: string); Overload;
  function IsBlacklisted(ip: string): boolean;
  function UserString(user: TUser): string;

const
  ReportColumns = 'game,username,filename,hash,record_count,rating,'+
    'merge_version,notes,date_submitted';
  UserColumns = 'ip,username,auth,firstSeen,lastSeen,timesSeen,download,'+
    'upload,timesRun,mergesBuilt,pluginsChecked,pluginsMerged,reportsSubmitted';
  BlacklistColumns = 'ip,username,created,expires';

  // MSG IDs
  MSG_NOTIFY = 0;
  MSG_REGISTER = 1;
  MSG_AUTH_RESET = 2;
  MSG_STATISTICS = 3;
  MSG_STATUS = 4;
  MSG_REQUEST = 5;
  MSG_REPORT = 6;

  // MSG Strings
  MSG_STRINGS: array[0..6] of string = (
    'MSG_NOTIFY',
    'MSG_REGISTER',
    'MSG_AUTH_RESET',
    'MSG_STATISTICS',
    'MSG_STATUS',
    'MSG_REQUEST',
    'MSG_REPORT'
  );

var
  TES5Dictionary, TES4Dictionary, FO3Dictionary, FNVDictionary,
  ApprovedReports, UnapprovedReports, Users, Blacklist, Log: TList;
  slTES5Dictionary, slTES4Dictionary, slFO3Dictionary, slFNVDictionary: TStringList;
  statistics: TStatistics;
  settings: TSettings;
  status: TmpStatus;
  TempPath, LogPath, ProgramPath: string;
  bLoginSuccess, bProgressCancel, bRebuildTES5, bRebuildTES4, bRebuildFNV,
  bRebuildFO3, bAscending: boolean;
  wbStartTime: TDateTime;
  sessionBandwidth: Int64;
  Connection: TZConnection;
  aColumnToSort: integer;

implementation

{******************************************************************************}
{ SQL Methods
  Methods for interacting with the SQL database.

  List of methods:
  - DoLogin
  - SQLQuery
  ==USERS==
  - QueryUsers
  - UserWhereClause
  - UserSetClause
  - UserValuesClause
  - UpdateUser
  - AddUser
  - RemoveUser
  ==BLACKLIST==
  - QueryBlacklist
  - BlacklistWhereClause
  - BlacklistSetClause
  - BlacklistValuesClause
  - UpdateBlacklist
  - AddBlacklist
  - RemoveBlacklist
  ==REPORTS==
  - QueryReports
  - ReportWhereClause
  - ReportSetClause
  - ReportValuesClause
  - UpdateReport
  - AddReport
  - RemoveReport
}
{******************************************************************************}

{ Attempt to login to MySQL database }
procedure DoLogin(userID, password, database, host, port: string);
begin
  // attempt to connect to mysql
  bLoginSuccess := false;
  try
    Connection := TZConnection.Create(nil);
    Connection.User := userID;
    Connection.Port := StrToInt(port);
    Connection.Database := database;
    Connection.Password := password;
    Connection.HostName := host;
    Connection.Protocol := 'mysql';
    Connection.Connect;
    bLoginSuccess := Connection.Connected;
    if not bLoginSuccess then
      ShowMessage('Failed to connect to database.');
  except
    on x : Exception do begin
      ShowMessage('Failed to connect: '#13#10+x.Message);
      Connection.Free;
    end;
  end;
end;

procedure SQLQuery(query: string);
var
  SQLQuery: TZQuery;
begin
  //Logger.Write('SQL', 'Query', query);
  SQLQuery := TZQuery.Create(nil);
  SQLQuery.Connection := Connection;
  SQLQuery.Fields.Clear;
  SQLQuery.SQL.Add(query);
  SQLQuery.ExecSQL;
  SQLQuery.Free;
end;

//========================================
// USERS
//========================================

procedure QueryUsers;
var
  Dataset: TZQuery;
  user: TUser;
  count: integer;
begin
  Users := TList.Create;

  // get users
  Dataset := TZQuery.Create(nil);
  Dataset.Connection := Connection;
  Dataset.Fields.Clear;
  Dataset.SQL.Add('SELECT '+UserColumns+' FROM users');
  Dataset.ExecSQL;
  Dataset.Open;

  // load into Users list
  count := 0;
  Dataset.First;
  while not Dataset.EOF do begin
    Inc(count);
    user := TUser.Create(Dataset.Fields);
    Users.Add(user);
    Dataset.Next;
  end;
  Logger.Write('SQL', 'Users', 'Loaded '+IntToStr(count)+' records');

  // clean up
  Dataset.Close;
  Dataset.Free;
end;

function UserWhereClause(user: TUser): string;
begin
  Result := 'WHERE '+
    'ip='''+user.ip+''' AND '+
    'username='''+user.username+'''';
end;

function UserSetClause(user: TUser): string;
begin
  Result := 'SET '+
    'ip='''+user.ip+''', '+
    'username='''+user.username+''', '+
    'auth='''+user.auth+''', '+
    'firstSeen='''+DateTimeToSQL(user.firstSeen)+''', '+
    'lastSeen='''+DateTimeToSQL(user.lastSeen)+''', '+
    'timesSeen='+IntToStr(user.timesSeen)+', '+
    'download='+IntToStr(user.download)+', '+
    'upload='+IntToStr(user.upload)+', '+
    'timesRun='+IntToStr(user.timesRun)+', '+
    'mergesBuilt='+IntToStr(user.mergesBuilt)+', '+
    'pluginsChecked='+IntToStr(user.pluginsChecked)+', '+
    'pluginsMerged='+IntToStr(user.pluginsMerged)+', '+
    'reportsSubmitted='+IntToStr(user.reportsSubmitted);
end;

function UserValuesClause(user: TUser): string;
begin
  Result := '('+UserColumns+') '+
    'VALUES ('''+
    user.ip+''','''+
    user.username+''','''+
    user.auth+''','''+
    DateTimeToSQL(user.firstSeen)+''','''+
    DateTimeToSQL(user.lastSeen)+''','+
    IntToStr(user.timesSeen)+','+
    IntToStr(user.download)+','+
    IntToStr(user.upload)+','+
    IntToStr(user.timesRun)+','+
    IntToStr(user.mergesBuilt)+','+
    IntToStr(user.pluginsChecked)+','+
    IntToStr(user.pluginsMerged)+','+
    IntToStr(user.reportsSubmitted)+')';
end;

procedure UpdateUser(SetClause, WhereClause: string);
var
  query: string;
begin
  Logger.Write('SQL', 'Users', 'Update '+WhereClause);
  query := 'UPDATE users '+SetClause+' '+WhereClause+';';
  SQLQuery(query);
end;

procedure AddUser(user: TUser);
var
  query, ValuesClause: string;
begin
  // execute SQL
  Logger.Write('SQL', 'Users', 'Add '+user.ip+' ('+user.username+')');
  ValuesClause := UserValuesClause(user);
  query := 'INSERT INTO users '+ValuesClause+';';
  SQLQuery(query);
end;

procedure RemoveUser(user: TUser);
var
  query, WhereClause: string;
begin
  // execute SQL
  WhereClause := UserWhereClause(user);
  Logger.Write('SQL', 'Users', 'Delete '+user.ip+' ('+user.username+')');
  query := 'DELETE FROM users '+WhereClause+';';
  SQLQuery(query);
end;

//========================================
// BLACKLIST
//========================================

procedure QueryBlacklist;
var
  Dataset: TZQuery;
  entry: TBlacklistEntry;
  count: integer;
begin
  Blacklist := TList.Create;

  // get blacklist
  Dataset := TZQuery.Create(nil);
  Dataset.Connection := Connection;
  Dataset.Fields.Clear;
  Dataset.SQL.Add('SELECT '+BlacklistColumns+' FROM blacklist');
  Dataset.ExecSQL;
  Dataset.Open;

  // load into Blacklist
  Dataset.First;
  count := 0;
  while not Dataset.EOF do begin
    Inc(count);
    entry := TBlacklistEntry.Create(Dataset.Fields);
    Blacklist.Add(entry);
    Dataset.Next;
  end;
  Logger.Write('SQL', 'Blacklist', 'Loaded '+IntToStr(count)+' records');

  // clean up
  Dataset.Close;
  Dataset.Free;
end;

function BlacklistWhereClause(entry: TBlacklistEntry): string;
begin
  Result := 'WHERE '+
    'ip='''+entry.ip+''' AND '+
    'username='''+entry.username+'''';
end;

function BlacklistSetClause(entry: TBlacklistEntry): string;
begin
  Result := 'SET '+
    'ip='''+entry.ip+''', '+
    'username='''+entry.username+''', '+
    'created='''+DateTimeToSQL(entry.created)+''', '+
    'expires='''+DateTimeToSQL(entry.expires)+'''';
end;

function BlacklistValuesClause(entry: TBlacklistEntry): string;
begin
  Result := '('+BlacklistColumns+') '+
    'VALUES ('''+
    entry.ip+''','''+
    entry.username+''','''+
    DateTimeToSQL(entry.created)+''','''+
    DateTimeToSQL(entry.expires)+''')';
end;

procedure UpdateBlacklist(SetClause, WhereClause: string);
var
  query: string;
begin
  query := 'UPDATE blacklist '+SetClause+' '+WhereClause+';';
  Logger.Write('SQL', 'Blacklist', 'Update '+WhereClause);
  SQLQuery(query);
end;

procedure AddBlacklist(entry: TBlacklistEntry);
var
  query, ValuesClause: string;
begin
  // execute SQL
  ValuesClause := BlacklistValuesClause(entry);
  query := 'INSERT INTO blacklist '+ValuesClause+';';
  Logger.Write('SQL', 'Blacklist', 'Add '+entry.ip+' ('+entry.username+')');
  SQLQuery(query);
end;

procedure RemoveBlacklist(entry: TBlacklistEntry);
var
  query, WhereClause: string;
begin
  // execute SQL
  WhereClause := BlacklistWhereClause(entry);
  query := 'DELETE FROM blacklist '+WhereClause+';';
  Logger.Write('SQL', 'Blacklist', 'Delete '+entry.ip+' ('+entry.username+')');
  SQLQuery(query);
end;

//========================================
// REPORTS
//========================================

{ Query database for Approved and Unapproved reports }
procedure QueryReports;
var
  Dataset: TZQuery;
  report: TReport;
  count: integer;
begin
  // initialize lists
  ApprovedReports := TList.Create;
  UnapprovedReports := TList.Create;

  // get approved_reports
  Dataset := TZQuery.Create(nil);
  Dataset.Connection := Connection;
  Dataset.Fields.Clear;
  Dataset.SQL.Add('SELECT '+ReportColumns+' FROM approved_reports');
  Dataset.ExecSQL;
  Dataset.Open;

  // load into ApprovedReports list
  count := 0;
  Dataset.First;
  while not Dataset.EOF do begin
    Inc(count);
    report := TReport.Create(Dataset.Fields);
    ApprovedReports.Add(report);
    Dataset.Next;
  end;
  Logger.Write('SQL', 'approved_reports', 'Loaded '+IntToStr(count)+' records');
  Dataset.Close;

  // get unapproved_reports
  Dataset := TZQuery.Create(nil);
  Dataset.Connection := Connection;
  Dataset.Fields.Clear;
  Dataset.SQL.Add('SELECT '+ReportColumns+' FROM unapproved_reports');
  Dataset.ExecSQL;
  Dataset.Open;

  // load into UnapprovedReports list
  count := 0;
  Dataset.First;
  while not Dataset.EOF do begin
    Inc(count);
    report := TReport.Create(Dataset.Fields);
    UnapprovedReports.Add(report);
    Dataset.Next;
  end;
  Logger.Write('SQL', 'unapproved_reports', 'Loaded '+IntToStr(count)+' records');
  Dataset.Close;
  Dataset.Free;
end;

function ReportWhereClause(report: TReport): string;
begin
  Result := 'WHERE '+
    'game='''+report.game+''' AND '+
    'username='''+report.username+''' AND '+
    'filename='''+report.filename+''' AND '+
    'merge_version='''+report.mergeVersion+'''';
end;

function ReportSetClause(report: TReport): string;
begin
  Result := 'SET '+
    'game='''+report.game+''', '+
    'username='''+report.username+''', '+
    'filename='''+report.filename+''', '+
    'hash='''+report.hash+''', '+
    'record_count='+IntToStr(report.recordCount)+', '+
    'rating='+IntToStr(report.rating)+', '+
    'merge_version='''+report.mergeVersion+''', '+
    'notes='''+StringReplace(Trim(report.notes.Text), #13#10, '@13', [rfReplaceAll])+'''';
end;

function ReportValuesClause(report: TReport): string;
begin
  Result := '('+ReportColumns+') '+
    'VALUES ('''+
    report.game+''','''+
    report.username+''','''+
    report.filename+''','''+
    report.hash+''','+
    IntToStr(report.recordCount)+','+
    IntToStr(report.rating)+','''+
    report.mergeVersion+''','''+
    StringReplace(Trim(report.notes.Text), #13#10, '@13', [rfReplaceAll])+''','''+
    DateTimeToSQL(report.dateSubmitted)+''')';
end;

procedure UpdateReport(report: TReport; SetClause, WhereClause: string);
var
  query: string;
begin
  query := 'UPDATE approved_reports '+SetClause+' '+WhereClause+';';
  Logger.Write('SQL', 'approved_reports', 'Update '+WhereClause);
  SQLQuery(query);
end;

procedure AddReport(report: TReport; table: string);
var
  query, ValuesClause: string;
begin
  // execute SQL
  ValuesClause := ReportValuesClause(report);
  query := 'INSERT INTO '+table+' '+ValuesClause+';';
  Logger.Write('SQL', table, 'Add '+report.game+', '+report.username+', '+report.filename);
  SQLQuery(query);
end;

procedure RemoveReport(report: TReport; table: string);
var
  query, WhereClause: string;
begin
  // execute SQL
  WhereClause := ReportWhereClause(report);
  query := 'DELETE FROM '+table+' '+WhereClause+';';
  Logger.Write('SQL', table, 'Delete '+report.game+', '+report.username+', '+report.filename);
  SQLQuery(query);
end;

{******************************************************************************}
{ General functions
  Set of functions that help with converting data formats and handling strings.

  List of functions:
  - csvText
  - FormatByteSize
  - DateBuiltString
  - IntegerListSum
}
{*****************************************************************************}

{ Replaces newlines with a comma and space }
function csvText(s: string): string;
begin
  result := StringReplace(Trim(s), #13, ', ', [rfReplaceAll]);
end;

{ Format file byte size }
function FormatByteSize(const bytes: Int64): string;
const
 B = 1; //byte
 KB = 1024 * B; //kilobyte
 MB = 1024 * KB; //megabyte
 GB = 1024 * MB; //gigabyte
begin
  if bytes > GB then
    result := FormatFloat('#.## GB', bytes / GB)
  else
    if bytes > MB then
      result := FormatFloat('#.## MB', bytes / MB)
    else
      if bytes > KB then
        result := FormatFloat('#.## KB', bytes / KB)
      else
        if bytes > 0 then
          result := FormatFloat('#.## bytes', bytes)
        else
          result := '0 bytes';
end;

{ Converts a TDateTime to a string, with 0 being the string 'Never' }
function DateBuiltString(date: TDateTime): string;
begin
  if date = 0 then
    Result := 'Never'
  else begin
    Result := DateTimeToStr(date);
  end;
end;

{ Converts a TdateTime to an SQL-compatible string }
function DateTimeToSQL(date: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:mm:ss', date);
end;

{ Converts an SQL-compatible date time string to a TDateTime }
function SQLToDateTime(date: string): TDateTime;
var
  fs: TFormatSettings;
begin
  GetLocaleFormatSettings(GetThreadLocale, fs);
  fs.DateSeparator := '-';
  fs.ShortDateFormat := 'yyyy-mm-dd';
  fs.TimeSeparator := ':';
  fs.LongTimeFormat := 'hh:nn:ss';
  Result := StrToDateTime(date, fs);
end;

{ Converts a TDateTime to a time string, e.g. 19d 20h 3m 30s }
function TimeStr(date: TDateTime): string;
begin
  Result := Format('%dd %dh %dm', [Trunc(date), HourOf(date), MinuteOf(date)]);
end;

{
  AppendIfMissing:
  Appends substr to the end of str if it's not already there.

  Example usage:
  s := 'This is a sample string.';
  Logger.Write(AppendIfMissing(s, 'string.')); //'This is a sample string.'
  Logger.Write(AppendIfMissing(s, '  Hello.')); //'This is a sample string.  Hello.'
}
function AppendIfMissing(str, substr: string): string;
begin
  Result := str;
  if Length(str) > Length(substr) then
    if Copy(str, Length(str) - Length(substr), Length(substr)) = substr then
      exit;

  Result := str + substr;
end;

{
  StrEndsWith:
  Checks to see if a string ends with an entered substring.

  Example usage:
  s := 'This is a sample string.';
  if StrEndsWith(s, 'string.') then
    AddMessage('It works!');
}
function StrEndsWith(s1, s2: string): boolean;
var
  n1, n2: integer;
begin
  Result := false;

  n1 := Length(s1);
  n2 := Length(s2);
  if n1 < n2 then exit;

  Result := (Copy(s1, n1 - n2 + 1, n2) = s2);
end;

{
  RemoveFromEnd:
  Creates a new string with s1 removed from the end of s2, if found.

  Example usage:
  s := 'This is a sample string.';
  AddMessage(RemoveFromEnd(s, 'string.')); //'This is a sample '
}
function RemoveFromEnd(s1, s2: string): string;
begin
  Result := s1;
  if StrEndsWith(s1, s2) then
    Result := Copy(s1, 1, Length(s1) - Length(s2));
end;

{ Calculates the integer sum of all values in a TList to maxIndex }
function IntegerListSum(list: TList; maxIndex: integer): integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to maxIndex do
    Inc(result, Integer(list[i]));
end;

{ Inserts line breaks in string @s before @charCount has been exceeded }
function Wordwrap(var s: string; charCount: integer): string;
var
  i, lastSpace, counter: Integer;
begin
  counter := 0;
  lastSpace := 0;
  for i := 1 to Length(s) do begin
    Inc(counter);
    if (s[i] = ' ') or (s[i] = ',') then
      lastSpace := i;
    if (s[i] = #13) or (s[i] = #10) then begin
      lastSpace := 0;
      counter := 0;
    end;
    if (counter = charCount) and (lastSpace > 0) then begin
      Insert(#13#10, s, lastSpace + 1);
      lastSpace := 0;
      counter := 0;
    end;
  end;
  Result := s;
end;

{ Checks to see if any mask in @sl matches the string @s }
function ContainsMatch(var sl: TStringList; const s: string): boolean;
var
  i: Integer;
begin
  Result := false;
  for i := 0 to Pred(sl.Count) do
    if MatchesMask(s, sl[i]) then begin
      Result := true;
      break;
    end;
end;

{ Returns true if the string is an http:// or https:// url }
function IsURL(s: string): boolean;
begin
  Result := (Pos('http://', s) = 1) or (Pos('https://', s) = 1);
end;

{ Returns the time the application has been running for }
function GetSessionUptime: TDateTime;
begin
  Result := Now - wbStartTime;
end;

{ Get program version from memory }
function GetVersionMem: string;
var
  verblock: PVSFIXEDFILEINFO;
  versionMS, versionLS, verlen: cardinal;
  rs: TResourceStream;
  m: TMemoryStream;
begin
  m := TMemoryStream.Create;
  try
    rs := TResourceStream.CreateFromID(HInstance, 1, RT_VERSION);
    try
      m.CopyFrom(rs, rs.Size);
    finally
      rs.Free;
    end;
    m.Position := 0;
    if VerQueryValue(m.Memory, '\', Pointer(verblock), verlen) then begin
      VersionMS := verblock.dwFileVersionMS;
      VersionLS := verblock.dwFileVersionLS;
      Result := Format('%s.%s.%s.%s', [IntToStr(versionMS shr 16),
        IntToStr(versionMS and $FFFF), IntToStr(VersionLS shr 16),
        IntToStr(VersionLS and $FFFF)]);
    end;
  finally
    m.Free;
  end;
end;

{ Get program version from disk }
function FileVersion(const FileName: string): String;
var
  VerInfoSize: Cardinal;
  VerValueSize: Cardinal;
  Dummy: Cardinal;
  PVerInfo: Pointer;
  PVerValue: PVSFixedFileInfo;
begin
  Result := '';
  VerInfoSize := GetFileVersionInfoSize(PChar(FileName), Dummy);
  GetMem(PVerInfo, VerInfoSize);
  try
    if GetFileVersionInfo(PChar(FileName), 0, VerInfoSize, PVerInfo) then
      if VerQueryValue(PVerInfo, '\', Pointer(PVerValue), VerValueSize) then
        with PVerValue^ do
          Result := Format('%d.%d.%d.%d', [
            HiWord(dwFileVersionMS), //Major
            LoWord(dwFileVersionMS), //Minor
            HiWord(dwFileVersionLS), //Release
            LoWord(dwFileVersionLS)]); //Build
  finally
    FreeMem(PVerInfo, VerInfoSize);
  end;
end;

function ApplyTemplate(const template: string; var map: TStringList): string;
const
  openTag = '{{';
  closeTag = '}}';
var
  i: Integer;
  name, value: string;
begin
  Result := template;
  for i := 0 to Pred(map.Count) do begin
    name := map.Names[i];
    value := map.ValueFromIndex[i];
    Result := StringReplace(Result, openTag + name + closeTag, value, [rfReplaceAll]);
  end;
end;


{******************************************************************************}
{ Windows API functions
  Set of functions that help deal with the Windows File System.

  List of functions:
  - GetCSIDLShellFolder
  - GetFileSize
  - GetLastModified
  - RecursiveFileSearch
}
{******************************************************************************}

{ Gets a folder by its integer CSID. }
function GetCSIDLShellFolder(CSIDLFolder: integer): string;
begin
  SetLength(Result, MAX_PATH);
  SHGetSpecialFolderPath(0, PChar(Result), CSIDLFolder, True);
  SetLength(Result, StrLen(PChar(Result)));
  if (Result <> '') then
    Result := IncludeTrailingBackslash(Result);
end;

{ Gets the size of a file at @aFilename through the windows API }
function GetFileSize(const aFilename: String): Int64;
var
  info: TWin32FileAttributeData;
begin
  result := -1;

  if NOT GetFileAttributesEx(PWideChar(aFileName), GetFileExInfoStandard, @info) then
    EXIT;

  result := Int64(info.nFileSizeLow) or Int64(info.nFileSizeHigh shl 32);
end;

{ Gets the last time a file was modified }
function GetLastModified(const aFileName: String): TDateTime;
var
  info: TWin32FileAttributeData;
  FileTime: TFileTime;
  LocalTime, SystemTime: TSystemTime;
begin
  result := 0;
  // exit if can't get attributes
  if not GetFileAttributesEx(PWideChar(aFileName), GetFileExInfoStandard, @info) then
    exit;

  // get last modified
  FileTime := info.ftLastWriteTime;

  // convert to system time
  if not FileTimeToSystemTime(FileTime, SystemTime) then
    RaiseLastOSError;
  if not SystemTimeToTzSpecificLocalTime(nil, SystemTime, LocalTime) then
    RaiseLastOSError;

  Result := SystemTimeToDateTime(LocalTime);
end;

{
  RecursiveFileSearch:
  Recursively searches a path for a file matching aFileName, ignoring
  directories in the ignore TStringList, and not traversing deeper than
  maxDepth.

  Example usage:
  ignore := TStringList.Create;
  ignore.Add('Data');
  p := RecursiveFileSearch('Skyrim.exe', GamePath, ignore, 1, false);
  AddMessage(p);
}
function RecursiveFileSearch(aPath, aFileName: string; ignore: TStringList; maxDepth: integer): string;
var
  skip: boolean;
  i: integer;
  rec: TSearchRec;
begin
  Result := '';
  aPath := AppendIfMissing(aPath, PathDelim);
  if Result <> '' then exit;
  // always ignore . and ..
  ignore.Add('.');
  ignore.Add('..');

  if FindFirst(aPath + '*', faAnyFile, rec) = 0 then begin
    repeat
      skip := false;
      for i := 0 to Pred(ignore.Count) do begin
        skip := Lowercase(rec.Name) = ignore[i];
        if skip then
          break;
      end;
      if not skip then begin
        if ((rec.attr and faDirectory) = faDirectory) and (maxDepth > 0) then begin
          Result := RecursiveFileSearch(aPath+rec.Name, aFileName, ignore, maxDepth - 1);
        end
        else if (rec.Name = aFileName) then
          Result := aPath + rec.Name;
      end;
      if (Result <> '') then break;
    until FindNext(rec) <> 0;

    FindClose(rec);
  end;
end;

{
  CopyDirectory:
  Recursively copies all of the contents of a directory.

  Example usage:
  slIgnore := TStringList.Create;
  slIgnore.Add('mteFunctions.pas');
  CopyDirectory(ScriptsPath, 'C:\ScriptsBackup', slIgnore);
}
procedure CopyDirectory(src, dst: string; fIgnore, dIgnore: TStringList);
var
  info: TSearchRec;
  isDirectory: boolean;
begin
  src := AppendIfMissing(src, PathDelim);
  dst := AppendIfMissing(dst, PathDelim);

  // if no files in source path, exit
  if (FindFirst(src + '*', faAnyFile, info) <> 0) then
    exit;
  repeat
    isDirectory := (info.Attr and faDirectory = faDirectory);
    // skip . and ..
    if (info.Name = '.') or (info.Name = '..') then
      continue;

    // skip if ignored
    if isDirectory and ContainsMatch(dIgnore, info.Name) then
      continue
    else if ContainsMatch(fIgnore, info.Name) then
      continue;

    // copy the file or recurse
    ForceDirectories(dst);
    if isDirectory then
      CopyDirectory(src+info.Name, dst+info.Name, fIgnore, dIgnore)
    else
      CopyFile(PChar(src+info.Name), PChar(dst+info.Name), false);
  until FindNext(info) <> 0;

  FindClose(info);
end;

{
  GetFilesList:
  Searches @path, recursively traversing subdirectories that don't match a mask
  in @dIgnore, adding files that don't match a mask in @fIgnore to @list.

  Example usage:
  FilesList := TStringList.Create;
  fileIgnore := TStringList.Create;
  fileIgnore.Add('*.esp');
  dirIgnore := TStringList.Create;
  dirIgnore.Add('translations');
  GetFilesList(wbDataPath, fileIgnore, dirIgnore, FilesList);
}
procedure GetFilesList(path: string; var fIgnore, dIgnore, list: TStringList);
var
  info: TSearchRec;
  isDirectory: boolean;
begin
  path := AppendIfMissing(path, PathDelim);

  // if no files in source path, exit
  if (FindFirst(path + '*', faAnyFile, info) <> 0) then
    exit;
  repeat
    isDirectory := (info.Attr and faDirectory = faDirectory);
    // skip . and ..
    if (info.Name = '.') or (info.Name = '..') then
      continue;

    // skip if ignored
    if isDirectory and ContainsMatch(dIgnore, info.Name) then
      continue
    else if ContainsMatch(fIgnore, info.Name) then
      continue;

    // copy the file or recurse
    if isDirectory then
      GetFilesList(path + info.Name, fIgnore, dIgnore, list)
    else
      list.Add(path + info.Name);
  until FindNext(info) <> 0;

  FindClose(info);
end;

{ Copies files in @list from @src to @dst }
procedure CopyFiles(src, dst: string; var list: TStringList);
var
  i: Integer;
  srcFile, dstFile: string;
begin
  src := AppendIfMissing(src, PathDelim);
  dst := AppendIfMissing(dst, PathDelim);
  for i := 0 to Pred(list.Count) do begin
    srcFile := list[i];
    dstFile := StringReplace(srcFile, src, dst, []);
    ForceDirectories(ExtractFilePath(dstFile));
    CopyFile(PChar(srcFile), PChar(dstFile), false);
  end;
end;


{******************************************************************************}
{ Data methods
  Set of methods for working with data.

  List of methods:
  - LoadSettings
  - SaveSettings
  - LoadStatistics
  - SaveStatistics
  - LoadDictionary
  - GetRatingColor
  - GetRating
  - IsBlackListed
  - GetEntry
}
{******************************************************************************}

procedure LoadSettings;
begin
  settings := TSettings.Create;
  settings.Load('settings.ini');
end;

procedure SaveSettings;
begin
  settings.Save('settings.ini');
end;

procedure LoadStatistics;
begin
  statistics := TStatistics.Create;
  statistics.Load('statistics.ini');
end;

procedure SaveStatistics;
begin
  statistics.Save('statistics.ini');
end;

procedure EntryNotes(var sl: TStringList; var report: TReport);
var
  header: string;
  slHeader: TStringList;
begin
  // prepare header
  slHeader := TStringList.Create;
  slHeader.Values['user'] := report.username;
  slHeader.Values['hash'] := report.hash;
  slHeader.Values['records'] := IntToStr(report.recordCount);
  slHeader.Values['version'] := report.mergeVersion;
  slHeader.Values['rating'] := IntToStr(report.rating);
  slHeader.Values['date'] := DateToStr(report.dateSubmitted);
  if (report.hash <> '0') then
    header := ApplyTemplate(settings.templateHash, slHeader)
  else
    header := ApplyTemplate(settings.templateNoHash, slHeader);

  // add to notes stringlist
  sl.Add(header);
  sl.Add(report.notes.Text);

  // clean up
  slHeader.Free;
end;

procedure SaveDictionary(game: string; var lst: TList);
var
  i: Integer;
  sl: TStringList;
  entry: TEntry;
begin
  sl := TStringList.Create;
  for i := 0 to Pred(lst.Count) do begin
    entry := TEntry(lst[i]);
    sl.Add(entry.ToText);
  end;
  sl.SaveToFile(game + 'Dictionary.txt');
  sl.Free;
end;

procedure RebuildDictionary(game: string; var lst: TList);
var
  i, n: integer;
  report: TReport;
  entry: TEntry;
  rating: real;
  sl: TStringList;
  bFilenameMatch, bHashMatch, bRecordsMatch, bVersionMatch: boolean;
begin
  Logger.Write('DICTIONARY', 'Build', game+' Dictionary');
  // sort reports so we can build dictionary entries faster
  bAscending := false;
  aColumnToSort := 1;
  ApprovedReports.Sort(CompareReports);

  // prepare to make new dictionary file
  lst.Clear;
  sl := TStringList.Create;
  rating := 0;
  n := 0;
  bFilenameMatch := false;
  bHashMatch := false;
  bRecordsMatch := false;
  bVersionMatch := false;
  entry := nil;

  // loop through approved reports
  for i := 0 to Pred(ApprovedReports.Count) do begin
    report := TReport(ApprovedReports[i]);
    // skip approved reports not for the game we're making the dictionary for
    if report.game <> game then
      continue;

    // process reports separately based on dictionary consolidation settings
    if Assigned(entry) then begin
      bFilenameMatch := SameText(entry.filename, report.filename);
      bHashMatch := (not settings.bSeparateHashes) or SameText(entry.hash, report.hash);
      bRecordsMatch := (not settings.bSeparateRecords) or (StrToInt(entry.records) = report.recordCount);
      bVersionMatch := (not settings.bSeparateVersions) or SameText(entry.version, report.mergeVersion);
    end;

    // thanks to sorting, we can make a single dictionary entry at a time
    if (bFilenameMatch and bHashMatch and bRecordsMatch and bVersionMatch) then begin
      Inc(n);
      rating := rating + report.rating;
      EntryNotes(sl, report);
    end
    else begin
      // add built entry to dictionary if it exists
      if (entry <> nil) then begin
        entry.rating := FormatFloat('0.##', (rating / (n * 1.0)));
        entry.reports := IntToStr(n);
        entry.notes := StringReplace(sl.Text, #13#10, '@13', [rfReplaceAll]);
        sl.Clear;
        lst.Add(entry);
      end;
      // prepare new entry
      entry := TEntry.Create;
      entry.filename := report.filename;
      entry.hash := report.hash;
      entry.records := IntToStr(report.recordCount);
      entry.version := report.mergeVersion;
      rating := report.rating;
      EntryNotes(sl, report);
      n := 1;
    end;
  end;

  // clean up
  sl.Free;
  // save dictionary
  SaveDictionary(game, lst);
  // refresh status
  status.Refresh;
end;

procedure RebuildDictionaries;
begin
  if bRebuildTES5 then RebuildDictionary('TES5', TES5Dictionary);
  if bRebuildTES4 then RebuildDictionary('TES4', TES4Dictionary);
  if bRebuildFNV then RebuildDictionary('FNV', FNVDictionary);
  if bRebuildFO3 then RebuildDictionary('FO3', FO3Dictionary);
end;

procedure UpdateRebuildBooleans(report: TReport);
begin
  if report.game = 'TES5' then bRebuildTES5 := true;
  if report.game = 'TES4' then bRebuildTES4 := true;
  if report.game = 'FNV' then bRebuildFNV := true;
  if report.game = 'FO3' then bRebuildFO3 := true;
end;

function GetDictionary(name: string): string;
begin
  if name = 'TES5Dictionary.txt' then
    Result := slTES5Dictionary.Text
  else if name = 'TES4Dictionary.txt' then
    Result := slTES4Dictionary.Text
  else if name = 'FNVDictionary.txt' then
    Result := slFNVDictionary.Text
  else if name = 'FO3Dictionary.txt' then
    Result := slFO3Dictionary.Text;
end;

function GetDictionaryHash(name: string): string;
begin
  if name = 'TES5Dictionary.txt' then
    Result := status.tes5hash
  else if name = 'TES4Dictionary.txt' then
    Result := status.tes4hash
  else if name = 'FNVDictionary.txt' then
    Result := status.fnvhash
  else if name = 'FO3Dictionary.txt' then
    Result := status.fo3hash;
end;

procedure LoadDictionary(var lst: TList; var sl: TStringList; filename: string);
var
  i: Integer;
  entry: TEntry;
begin
  // don't attempt to load dictionary if it doesn't exist
  if not FileExists(filename) then begin
    Logger.Write('INIT', 'Error', 'No dictionary file '+filename);
    exit;
  end;

  // load dictionary file
  sl := TStringList.Create;
  sl.LoadFromFile(filename);

  // load dictionary file into entry object
  for i := 0 to Pred(sl.Count) do begin
    entry := TEntry.Create(sl[i]);
    lst.Add(entry);
  end;
end;

procedure LoadBlacklist(var lst, dictionary: TList);
var
  i: Integer;
  entry: TEntry;
begin
  for i := 0 to Pred(dictionary.Count) do begin
    entry := TEntry(dictionary[i]);
    if entry.rating = '-1' then
      lst.Add(entry);
  end;
end;

function GetRatingColor(rating: real): integer;
var
  k1, k2: real;
  r, g: byte;
begin
  if rating = -2.0 then begin
    Result := $707070;
    exit;
  end;

  if rating = -1.0 then begin
    Result := $000000;
    exit;
  end;

  if (rating > 2.0) then begin
    k2 := (rating - 2.0)/2.0;
    k1 := 1.0 - k2;
    r := Trunc($E5 * k1 + $00 * k2);
    g := Trunc($A8 * k1 + $90 * k2);
  end
  else begin
    k2 := (rating/2.0);
    k1 := 1.0 - k2;
    r := Trunc($FF * k1 + $E5 * k2);
    g := Trunc($00 * k1 + $A8 * k2);
  end;

  Result := g * 256 + r;
end;

function GetEntry(var dictionary: TList; pluginName, numRecords, version: string): TEntry;
var
  i: Integer;
  entry: TEntry;
begin
  Result := TEntry.Create;
  for i := 0 to Pred(dictionary.Count) do begin
    entry := TEntry(dictionary[i]);
    if entry.filename = pluginName then begin
      Result := entry;
      exit;
    end;
  end;
end;

procedure SaveLog(var Log: TList);
var
  sl: TStringList;
  i: Integer;
  msg: TLogMessage;
  fdt: string;
begin
  sl := TStringList.Create;
  for i := 0 to Pred(Log.Count) do begin
    msg := TLogMessage(Log[i]);
    sl.Add(Format('[%s] (%s) %s: %s', [msg.time, msg.group, msg.&label, msg.text]));
  end;
  fdt := FormatDateTime('mmddyy_hhnnss', TDateTime(Now));
  ForceDirectories(LogPath);
  sl.SaveToFile(LogPath+'log_'+fdt+'.txt');
  sl.Free;
end;

function CompareReports(P1, P2: Pointer): Integer;
var
  report1, report2: TReport;
begin
  Result := 0;
  report1 := TReport(P1);
  report2 := TReport(P2);

  if aColumnToSort = 0 then
    Result := AnsiCompareText(report1.game, report2.game)
  else if aColumnToSort = 1 then
    Result := AnsiCompareText(report1.filename, report2.filename)
  else if aColumnToSort = 2 then
    Result := Trunc(report1.dateSubmitted) - Trunc(report2.dateSubmitted)
  else if aColumnToSort = 3 then
    Result := AnsiCompareText(report1.username, report2.username)
  else if aColumnToSort = 4 then
    Result := report1.rating - report2.rating;

  if bAscending then
    Result := -Result;
end;

{******************************************************************************}
{ User methods
  Set of methods for handling users.

  List of method:
  - Authorized
  - ResetAuth
  - GetUser
  - GetUser
}
{******************************************************************************}


function Authorized(ip, username, auth: string): boolean;
var
  i: Integer;
  user: TUser;
  WhereClause, SetClause: string;
begin
  Result := false;
  for i := 0 to Pred(Users.Count) do begin
    user := TUser(Users[i]);
    if SameText(user.username, username) then begin
      Result := SameText(user.auth, auth);
      if Result and not SameText(user.ip, ip) then begin
        WhereClause := UserWhereClause(user);
        user.ip := ip;
        SetClause := UserSetClause(user);
        UpdateUser(SetClause, WhereClause);
      end;
      exit;
    end;
  end;
end;

function ResetAuth(ip, username, auth: string): boolean;
var
  i: Integer;
  user: TUser;
  SetClause, WhereClause: string;
begin
  Result := false;
  for i := 0 to Pred(Users.Count) do begin
    user := TUser(Users[i]);
    if SameText(user.username, username) then begin
      Result := SameText(user.ip, ip);
      if Result then begin
        WhereClause := UserWhereClause(user);
        user.auth := auth;
        SetClause := UserSetClause(user);
        UpdateUser(SetClause, WhereClause);
      end;
      exit;
    end;
  end;
end;

function GetUser(ip, username, auth: string): TUser;
var
  i: Integer;
  user: TUser;
begin
  Result := nil;
  for i := 0 to Pred(Users.Count) do begin
    user := TUser(Users[i]);
    if SameText(user.username, username) then begin
      if SameText(user.auth, auth) and SameText(user.ip, ip) then
        Result := user;
      exit; // exit if user auth or ip differs with stored values
    end;
  end;
end;

function GetUser(ip: string): TUser;
var
  i: Integer;
  user: TUser;
begin
  Result := nil;
  for i := 0 to Pred(Users.Count) do begin
    user := TUser(Users[i]);
    if SameText(user.ip, ip) then begin
      Result := user;
      exit;
    end;
  end;
end;

function AddUser(ip: string): TUser;
var
  user: TUser;
begin
  user := TUser.Create(ip);
  Users.Add(user);
  AddUser(user);
  Result := user;
end;

procedure UpdateUser(ip, username, auth: string);
var
  WhereClause, SetClause: string;
  user: TUser;
begin
  user := GetUser(ip);
  WhereClause := UserWhereClause(user);
  user.username := username;
  user.auth := auth;
  SetClause := UserSetClause(user);
  UpdateUser(SetClause, WhereClause);
end;

function IsBlacklisted(ip: string): boolean;
var
  i: Integer;
  entry: TBlacklistEntry;
begin
  Result := false;
  for i := 0 to Pred(Blacklist.Count) do begin
    entry := TBlacklistEntry(Blacklist[i]);
    if SameText(ip, entry.ip) then begin
      Result := true;
      exit;
    end;
  end;
end;

function UserString(user: TUser): string;
begin
  Result := user.ip;
  if user.username <> '' then
    Result := Result + ' ('+user.username+')';
end;


{******************************************************************************}
{ Object methods
  Set of methods for objects TMerge and TPlugin

  List of methods:
  - TLogMessage.Create
  - TBlacklistEntry.Create
  - TBlacklistEntry.Create
  - TUser.Create
  - TUser.Dump
  - TUser.LoadDump
  - TmpMessage.Create
  - TmpMessage.ToJson
  - TmpMessage.FromJson
  - TmpStatus.ToJson
  - TmpStatus.FromJson
  - TReport.Create
  - TReport.Create
  - TReport.ToJson
  - TReport.FromJson
  - TEntry.Create
  - TSettings.Create
  - TSettings.Save
  - TSettings.Load
  - TStatistics.Create
  - TStatistics.Save
  - TStatistics.Load
}
{******************************************************************************}

constructor TLogMessage.Create(time, group, &label, text: string);
begin
  self.time := time;
  self.group := group;
  self.&label := &label;
  self.text := text;
end;

constructor TBlacklistEntry.Create(ip, username: string; duration: real);
begin
  self.ip := ip;
  self.username := username;
  created := Now;
  expires := created + duration;
end;

constructor TBlacklistEntry.Create(const fields: TFields);
begin
  ip := fields[0].AsString;
  username := fields[1].AsString;
  created := fields[2].AsDateTime;
  expires := fields[3].AsDateTime;
end;

constructor TUser.Create(ip: string);
begin
  self.ip := ip;
  firstSeen := Now;
  lastSeen := Now;
end;

constructor TUser.Create(const fields: TFields);
begin
  ip := fields[0].AsString;
  username := fields[1].AsString;
  auth := fields[2].AsString;
  firstSeen := fields[3].AsDateTime;
  lastSeen := fields[4].AsDateTime;
  timesSeen := fields[5].AsInteger;
  download := fields[6].AsLargeInt;
  upload := fields[7].AsLargeInt;
  timesRun := fields[8].AsInteger;
  mergesBuilt := fields[9].AsInteger;
  pluginsChecked := fields[10].AsInteger;
  pluginsMerged := fields[11].AsInteger;
  reportsSubmitted := fields[12].AsInteger;
end;

{ TmpMessage Constructor }
constructor TmpMessage.Create(id: integer; username, auth, data: string);
begin
  self.id := id;
  self.username := username;
  self.auth := auth;
  self.data := data;
end;

{ TmpMessage to json string }
function TmpMessage.ToJson: string;
var
  obj: ISuperObject;
begin
  obj := SO;

  // filename, hash, errors
  obj.I['id'] := id;
  obj.S['username'] := username;
  obj.S['auth'] := auth;
  obj.S['data'] := data;

  Result := obj.AsJSon;
end;

{ Json string to TmpMessage }
procedure TmpMessage.FromJson(json: string);
var
  obj: ISuperObject;
begin
  obj := SO(PChar(json));

  id := obj.I['id'];
  username := obj.S['username'];
  auth := obj.S['auth'];
  data := obj.S['data'];
end;

{ TmpStatus to json string }
function TmpStatus.ToJson: string;
var
  obj: ISuperObject;
begin
  obj := SO;

  obj.S['ProgramVersion'] := ProgramVersion;
  obj.S['TES5Hash'] := TES5Hash;
  obj.S['TES4Hash'] := TES4Hash;
  obj.S['FNVHash'] := FNVHash;
  obj.S['FO3Hash'] := FO3Hash;

  Result := obj.AsJSon;
end;

{ Json string to TmpStatus }
procedure TmpStatus.FromJson(json: string);
var
  obj: ISuperObject;
begin
  obj := SO(PChar(json));

  ProgramVersion := obj.S['ProgramVersion'];
  TES5Hash := obj.S['TES5Hash'];
  TES4Hash := obj.S['TES4Hash'];
  FNVHash := obj.S['FNVHash'];
  FO3Hash := obj.S['FO3Hash'];
end;

procedure TmpStatus.Refresh;
var
  NewVersion: string;
  Zipper: TAbZipper;
begin
  if FileExists('MergePlugins.exe') then begin
    NewVersion := FileVersion('MergePlugins.exe');
    if (ProgramVersion <> NewVersion) then begin
      Zipper := TAbZipper.Create(nil);
      Zipper.AutoSave := true;
      Zipper.FileName := 'MergePlugins.zip';
      Zipper.StoreOptions := [soStripDrive, soStripPath, soRemoveDots, soReplace];
      Zipper.AddFiles('MergePlugins.exe', 0);
      ProgramVersion := NewVersion;
      Logger.Write('INIT', 'Status', 'Client Version: '+ProgramVersion);
      Zipper.Free;
    end;
  end;
  if FileExists('TES5Dictionary.txt') then begin
    NewVersion := GetCRC32('TES5Dictionary.txt');
    if (TES5Hash <> NewVersion) then begin
      TES5Hash := NewVersion;
      Logger.Write('INIT', 'Status', 'TES5Dictionary Hash: '+TES5Hash);
    end;
  end;
  if FileExists('TES4Dictionary.txt') then begin
    NewVersion := GetCRC32('TES4Dictionary.txt');
    if (TES4Hash <> NewVersion) then begin
      TES4Hash := NewVersion;
      Logger.Write('INIT', 'Status', 'TES4Dictionary Hash: '+TES4Hash);
    end;
  end;
  if FileExists('FNVDictionary.txt') then begin
    NewVersion := GetCRC32('FNVDictionary.txt');
    if (FNVHash <> NewVersion) then begin
      FNVHash := NewVersion;
      Logger.Write('INIT', 'Status', 'FNVDictionary Hash: '+FNVHash);
    end;
  end;
  if FileExists('FO3Dictionary.txt') then begin
    NewVersion := GetCRC32('FO3Dictionary.txt');
    if (FO3Hash <> NewVersion) then begin
      FO3Hash := NewVersion;
      Logger.Write('INIT', 'Status', 'FO3Dictionary Hash: '+FO3Hash);
    end;
  end;
end;

{ TReport Constructor }
constructor TReport.Create;
begin
  notes := TStringList.Create;
end;

constructor TReport.Create(const fields: TFields);
var
  s: string;
begin
  game := fields[0].AsString;
  username := fields[1].AsString;
  filename := fields[2].AsString;
  hash := fields[3].AsString;
  recordCount := fields[4].AsInteger;
  rating := fields[5].AsInteger;
  mergeVersion := fields[6].AsString;
  notes := TStringList.Create;
  s := StringReplace(fields[7].AsString, '@13', #13#10, [rfReplaceAll]);
  notes.Text := Wordwrap(s, 70);
  dateSubmitted := fields[8].AsDateTime;
end;

{ TReport to json string }
function TReport.ToJson: string;
var
  obj: ISuperObject;
begin
  obj := SO;

  obj.S['game'] := game;
  obj.S['username'] := username;
  obj.S['filename'] := filename;
  obj.S['hash'] := hash;
  obj.I['recordCount'] := recordCount;
  obj.I['rating'] := rating;
  obj.S['mergeVersion'] := mergeVersion;
  obj.S['notes'] := StringReplace(notes.Text, #13#10, '@13', [rfReplaceAll]);
  obj.S['dateSubmitted'] := DateTimeToSQL(dateSubmitted);

  Result := obj.AsJSon;
end;

{ Json string to TReport }
procedure TReport.FromJson(json: string);
var
  obj: ISuperObject;
begin
  obj := SO(PChar(json));

  game := obj.S['game'];
  username := obj.S['username'];
  filename := obj.S['filename'];
  hash := obj.S['hash'];
  recordCount := obj.I['recordCount'];
  rating := obj.I['rating'];
  mergeVersion := obj.S['mergeVersion'];
  notes.Text := obj.S['notes'];
  dateSubmitted := SQLToDateTime(obj.S['dateSubmitted']);
end;

{ TEntry Constructor }
constructor TEntry.Create;
begin
  reports := '0';
  rating := 'No rating';
end;

constructor TEntry.Create(const s: string);
var
  i, lastIndex, ct: Integer;
begin
  lastIndex := 1;
  ct := 0;
  for i := 1 to Length(s) do begin
    if s[i] = ';' then begin
      if ct = 0 then
        filename := Copy(s, lastIndex, i - lastIndex)
      else if ct = 1 then
        records := Copy(s, lastIndex, i - lastIndex)
      else if ct = 2 then
        version := Copy(s, lastIndex, i - lastIndex)
      else if ct = 3 then
        rating := Copy(s, lastIndex, i - lastIndex)
      else if ct = 4 then begin
        reports := Copy(s, lastIndex, i - lastIndex);
        notes := Copy(s, i + 1, Length(s));
      end;
      LastIndex := i + 1;
      Inc(ct);
    end;
  end;
end;

function TEntry.ToText: string;
begin
  Result := filename + ';' + records + ';' + version + ';' + rating + ';' +
    reports + ';' + notes;
end;

{ TSettings constructor }
constructor TSettings.Create;
begin
  serverMessageColor := clBlue;
  initMessageColor := clGreen;
  SQLMessageColor := clSkyBlue;
  dictionaryMessageColor := $0000CCFF;
  javaMessageColor := $000080FF;
  errorMessageColor := clRed;
end;

{ Load settings from settings.json }
procedure TSettings.Load(const filename: string);
var
  obj: ISuperObject;
  sl: TStringList;
begin
  // don't load file if it doesn't exist
  if not FileExists(filename) then
    exit;

  // load file into SuperObject to parse it
  sl := TStringList.Create;
  sl.LoadFromFile(filename);
  obj := SO(PChar(sl.Text));

  // load log colors
  serverMessageColor := TColor(obj.I['serverMessageColor']);
  initMessageColor := TColor(obj.I['initMessageColor']);
  SQLMessageColor := TColor(obj.I['SQLMessageColor']);
  dictionaryMessageColor := TColor(obj.I['dictionaryMessageColor']);
  javaMessageColor := TColor(obj.I['javaMessageColor']);
  errorMessageColor := TColor(obj.I['errorMessageColor']);

  // load style choices
  simpleLogView := obj.B['simpleLogView'];
  simpleDictionaryView := obj.B['simpleDictionaryView'];
  simpleReportsView := obj.B['simpleReportsView'];

  // load dictionary options
  bSeparateHashes := obj.B['separateHashes'];
  bSeparateRecords := obj.B['separateRecords'];
  bSeparateVersions := obj.B['separateVersions'];
  templateHash := obj.S['templateHash'];
  templateNoHash := obj.S['templateNoHash'];

  // finalize
  obj := nil;
  sl.Free;
end;

{ Save settings to settings.json }
procedure TSettings.Save(const filename: string);
var
  obj: ISuperObject;
begin
  // initialize json
  obj := SO;

  // save log colors
  obj.I['serverMessageColor'] := Integer(serverMessageColor);
  obj.I['initMessageColor'] := Integer(initMessageColor);
  obj.I['SQLMessageColor'] := Integer(SQLMessageColor);
  obj.I['dictionaryMessageColor'] := Integer(dictionaryMessageColor);
  obj.I['javaMessageColor'] := Integer(javaMessageColor);
  obj.I['errorMessageColor'] := Integer(errorMessageColor);

  // save style choices
  obj.B['simpleLogView'] := simpleLogView;
  obj.B['simpleDictionaryView'] := simpleDictionaryView;
  obj.B['simpleReportsView'] := simpleReportsView;

  // save dictionary options
  obj.B['separateHashes'] := bSeparateHashes;
  obj.B['separateRecords'] := bSeparateRecords;
  obj.B['separateVersions'] := bSeparateVersions;
  obj.S['templateHash'] := templateHash;
  obj.S['templateNoHash'] := templateNoHash;

  // save and finalize
  Tracker.Write(' ');
  Tracker.Write('Saving to '+filename);
  obj.SaveTo(filename);
  obj := nil;
end;

{ TStatistics constructor }
constructor TStatistics.Create;
begin
  timesRun := 0;
  dictionaryUpdates := 0;
  programUpdates := 0;
  reportsRecieved := 0;
  reportsApproved := 0;
  reportsDenied := 0;
  totalBandwidth := 0;
  totalUptime := 0;
  tes5Reports := 0;
  tes4Reports := 0;
  fnvReports := 0;
  fo3Reports := 0;
  tes5Logins := 0;
  tes4Logins := 0;
  fnvLogins := 0;
  fo3Logins := 0;
end;

procedure TStatistics.Save(const filename: string);
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(filename);
  ini.WriteInteger('Statistics', 'timesRun', timesRun);
  ini.WriteInteger('Statistics', 'dictionaryUpdates', dictionaryUpdates);
  ini.WriteInteger('Statistics', 'programUpdates', programUpdates);
  ini.WriteInteger('Statistics', 'reportsRecieved', reportsRecieved);
  ini.WriteInteger('Statistics', 'reportsApproved', reportsApproved);
  ini.WriteInteger('Statistics', 'reportsDenied', reportsDenied);
  ini.WriteInteger('Statistics', 'totalBandwidth', totalBandwidth);
  ini.WriteFloat('Statistics', 'totalUptime', totalUptime);
  ini.WriteInteger('Statistics', 'tes5ReportsRecieved', tes5Reports);
  ini.WriteInteger('Statistics', 'tes4ReportsRecieved', tes4Reports);
  ini.WriteInteger('Statistics', 'fnvReportsRecieved', fnvReports);
  ini.WriteInteger('Statistics', 'fo3ReportsRecieved', fo3Reports);
  ini.WriteInteger('Statistics', 'tes5Logins', tes5Logins);
  ini.WriteInteger('Statistics', 'tes4Logins', tes4Logins);
  ini.WriteInteger('Statistics', 'fnvLogins', fnvLogins);
  ini.WriteInteger('Statistics', 'fo3Logins', fo3Logins);

  // save file
  ini.UpdateFile;
  ini.Free;
end;

procedure TStatistics.Load(const filename: string);
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(filename);
  timesRun := ini.ReadInteger('Statistics', 'timesRun', 0);
  dictionaryUpdates := ini.ReadInteger('Statistics', 'dictionaryUpdates', 0);
  programUpdates := ini.ReadInteger('Statistics', 'programUpdates', 0);
  reportsRecieved := ini.ReadInteger('Statistics', 'reportsRecieved', 0);
  reportsApproved := ini.ReadInteger('Statistics', 'reportsApproved', 0);
  reportsDenied := ini.ReadInteger('Statistics', 'reportsDenied', 0);
  totalBandwidth := ini.ReadInteger('Statistics', 'totalBandwidth', 0);
  totalUptime := ini.ReadFloat('Statistics', 'totalUptime', 0);
  tes5Reports := ini.ReadInteger('Statistics', 'tes5ReportsRecieved', 0);
  tes4Reports := ini.ReadInteger('Statistics', 'tes4ReportsRecieved', 0);
  fnvReports := ini.ReadInteger('Statistics', 'fnvReportsRecieved', 0);
  fo3Reports := ini.ReadInteger('Statistics', 'fo3ReportsRecieved', 0);
  tes5Logins := ini.ReadInteger('Statistics', 'tes5Logins', 0);
  tes4Logins := ini.ReadInteger('Statistics', 'tes4Logins', 0);
  fnvLogins := ini.ReadInteger('Statistics', 'fnvLogins', 0);
  fo3Logins := ini.ReadInteger('Statistics', 'fo3Logins', 0);

  // save file
  ini.UpdateFile;
  ini.Free;
end;



end.
