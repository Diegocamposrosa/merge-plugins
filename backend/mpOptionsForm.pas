unit mpOptionsForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, Buttons, ImgList, FileCtrl,
  mpBackend, ExtCtrls, Menus;

type
  TOptionsForm = class(TForm)
    SettingsPageControl: TPageControl;
    GeneralTabSheet: TTabSheet;
    btnCancel: TButton;
    btnOK: TButton;
    IconList: TImageList;
    gbStatus: TGroupBox;
    lblVersion: TLabel;
    lblTES5Hash: TLabel;
    lblTES4Hash: TLabel;
    lblTES4HashValue: TLabel;
    lblFNVHash: TLabel;
    lblFNVHashValue: TLabel;
    lblFO3Hash: TLabel;
    lblFO3HashValue: TLabel;
    lblVersionValue: TLabel;
    lblTES5HashValue: TLabel;
    btnUpdateStatus: TButton;
    gbBlacklist: TGroupBox;
    lvBlacklist: TListView;
    pmBlacklist: TPopupMenu;
    UnblacklistItem: TMenuItem;
    ChangeExpirationItem: TMenuItem;
    UsersTabsheet: TTabSheet;
    GroupBox1: TGroupBox;
    lvUsers: TListView;
    gbColoring: TGroupBox;
    lblServerColor: TLabel;
    lblInitColor: TLabel;
    lblSQLColor: TLabel;
    lblDictionaryColor: TLabel;
    lblJavaColor: TLabel;
    lblErrorColor: TLabel;
    cbServerColor: TColorBox;
    cbInitColor: TColorBox;
    cbSQLColor: TColorBox;
    cbDictionaryColor: TColorBox;
    cbJavaColor: TColorBox;
    cbErrorColor: TColorBox;
    gbStyle: TGroupBox;
    kbSimpleReports: TCheckBox;
    kbSimpleLog: TCheckBox;
    kbSimpleDictionary: TCheckBox;
    pmUsers: TPopupMenu;
    BlacklistUserItem: TMenuItem;
    ViewUserItem: TMenuItem;
    DeleteUserItem: TMenuItem;
    procedure btnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnUpdateStatusClick(Sender: TObject);
    procedure lvUsersData(Sender: TObject; Item: TListItem);
    procedure lvBlacklistData(Sender: TObject; Item: TListItem);
    procedure ViewUserItemClick(Sender: TObject);
    procedure BlacklistUserItemClick(Sender: TObject);
    procedure DeleteUserItemClick(Sender: TObject);
    procedure pmUsersPopup(Sender: TObject);
    procedure pmBlacklistPopup(Sender: TObject);
    procedure UnblacklistItemClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  OptionsForm: TOptionsForm;

implementation

{$R *.dfm}

procedure TOptionsForm.btnOKClick(Sender: TObject);
begin
  // save log coloring
  settings.serverMessageColor := cbServerColor.Selected;
  settings.initMessageColor := cbInitColor.Selected;
  settings.SQLMessageColor := cbSQLColor.Selected;
  settings.dictionaryMessageColor := cbDictionaryColor.Selected;
  settings.javaMessageColor := cbJavaColor.Selected;
  settings.errorMessageColor := cbErrorColor.Selected;

  // save style
  settings.simpleLogView := kbSimpleLog.Checked;
  settings.simpleReportsView := kbSimpleReports.Checked;
  settings.simpleDictionaryView := kbSimpleDictionary.Checked;

  // save to disk
  settings.Save('settings.ini');
end;

procedure TOptionsForm.btnUpdateStatusClick(Sender: TObject);
begin
  status := TmpStatus.Create;

  // load status values
  lblVersionValue.Caption := status.programVersion;
  lblTES5HashValue.Caption := status.tes5Hash;
  lblTES4HashValue.Caption := status.tes4Hash;
  lblFNVHashValue.Caption := status.fnvHash;
  lblFO3HashValue.Caption := status.fo3Hash;
end;

procedure TOptionsForm.FormCreate(Sender: TObject);
begin
  // load status values
  lblVersionValue.Caption := status.programVersion;
  lblTES5HashValue.Caption := status.tes5Hash;
  lblTES4HashValue.Caption := status.tes4Hash;
  lblFNVHashValue.Caption := status.fnvHash;
  lblFO3HashValue.Caption := status.fo3Hash;

  // load color choices
  cbServerColor.Selected := settings.serverMessageColor;
  cbInitColor.Selected := settings.initMessageColor;
  cbSQLColor.Selected := settings.sqlMessageColor;
  cbDictionaryColor.Selected := settings.dictionaryMessageColor;
  cbJavaColor.Selected := settings.javaMessageColor;
  cbErrorColor.Selected := settings.errorMessageColor;

  // load style choices
  kbSimpleLog.Checked := settings.simpleLogView;
  kbSimpleDictionary.Checked := settings.simpleDictionaryView;
  kbSimpleReports.Checked := settings.simpleReportsView;

  // load ips
  lvBlacklist.Items.Count := Blacklist.Count;
  lvUsers.Items.Count := Users.Count;
end;

procedure TOptionsForm.lvBlacklistData(Sender: TObject; Item: TListItem);
var
  entry: TBlacklistEntry;
begin
  if Item.Index > Pred(Blacklist.Count) then
    exit;
  entry := TBlacklistEntry(Blacklist[Item.Index]);
  Item.Caption := entry.IP;
  Item.SubItems.Add(entry.username);
  Item.SubItems.Add(FormatDateTime('mm/dd/yyyy hh:nn', entry.created));
  Item.SubItems.Add(FormatDateTime('mm/dd/yyyy hh:nn', entry.expires));
end;

procedure TOptionsForm.lvUsersData(Sender: TObject; Item: TListItem);
var
  user: TUser;
begin
  if Item.Index > Pred(Users.Count) then
    exit;
  user := TUser(Users[Item.Index]);
  Item.Caption := user.IP;
  Item.SubItems.Add(user.username);
  Item.SubItems.Add(FormatDateTime('mm/dd/yyyy hh:nn', user.firstSeen));
  Item.SubItems.Add(FormatDateTime('mm/dd/yyyy hh:nn', user.lastSeen));
end;

procedure TOptionsForm.pmBlacklistPopup(Sender: TObject);
var
  i: Integer;
  bSelected: boolean;
begin
  bSelected := false;
  for i := 0 to Pred(lvBlacklist.Items.Count) do begin
    bSelected := bSelected or lvBlacklist.Items[i].Selected;
  end;

  UnblacklistItem.Enabled := bSelected;
  ChangeExpirationItem.Enabled := bSelected;
end;

procedure TOptionsForm.UnblacklistItemClick(Sender: TObject);
var
  i: integer;
  entry: TBlacklistEntry;
begin
  for i := Pred(lvBlacklist.Items.Count) downto 0 do begin
    if not lvBlacklist.Items[i].Selected then
      continue;
    entry := TBlacklistEntry(Blacklist[i]);
    RemoveBlacklist(entry);
    Blacklist.Remove(entry);
    lvBlacklist.Items.Count := Blacklist.Count;
  end;
end;

procedure TOptionsForm.pmUsersPopup(Sender: TObject);
var
  i: Integer;
  bSelected: boolean;
begin
  bSelected := false;
  for i := 0 to Pred(lvUsers.Items.Count) do begin
    bSelected := bSelected or lvUsers.Items[i].Selected;
  end;

  ViewUserItem.Enabled := bSelected;
  BlacklistUserItem.Enabled := bSelected;
  DeleteUserItem.Enabled := bSelected;
end;

procedure TOptionsForm.ViewUserItemClick(Sender: TObject);
begin
  // ?
end;

procedure TOptionsForm.BlacklistUserItemClick(Sender: TObject);
var
  i: Integer;
  user: TUser;
  entry: TBlacklistEntry;
  duration: real;
  sDuration: string;
begin
  for i := Pred(lvUsers.Items.Count) downto 0 do begin
    if not lvUsers.Items[i].Selected then
      continue;
    user := TUser(Users[i]);
    sDuration := '30.0';
    if not InputQuery('Blacklist Duration', 'Duration to blacklist '+user.ip+' ('+user.username+')', sDuration) then
      continue;
    duration := StrToFloat(sDuration);
    entry := TBlacklistEntry.Create(user.ip, user.username, duration);
    Blacklist.Add(entry);
    AddBlacklist(entry);
    lvBlacklist.Items.Count := Blacklist.Count;
  end;
end;

procedure TOptionsForm.DeleteUserItemClick(Sender: TObject);
var
  i: Integer;
  user: TUser;
begin
  for i := Pred(lvUsers.Items.Count) downto 0 do begin
    if not lvUsers.Items[i].Selected then
      continue;
    user := TUser(Users[i]);
    if MessageDlg('Are you sure you want to delete '+user.ip+' ('+user.username+')?',
      mtConfirmation, [mbYes, mbNo], 0) = mrNo then
      continue;
    RemoveUser(user);
    Users.Remove(user);
    lvUsers.Items.Count := Users.Count;
  end;
end;

end.