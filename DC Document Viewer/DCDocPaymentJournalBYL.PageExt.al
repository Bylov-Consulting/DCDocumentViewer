
pageextension 71851576 "DC Doc Payment Journal BYL" extends "Payment Journal"
{
    layout
    {
        addfirst(FactBoxes)
        {
            part(CDCCaptureUIBYL; "DC Addin Payment Journal BYL")
            {
                Caption = 'Document';
                SubPageLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field("Journal Batch Name"), "Line No." = field("Line No.");
                SubPageView = sorting("Line No.");
                ApplicationArea = Basic, Suite;
                AccessByPermission = tabledata "CDC Document Capture Setup" = R;
                Visible = CDCHasDCDocument;
            }
        }
    }
    var
        CDCHasAccess: Boolean;
        CDCHasDCDocument: Boolean;

    trigger OnOpenPage()
    begin
        CDCCheckIfHasAccess();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if CDCHasAccess then
            CDCEnableFields();
    end;

    local procedure CDCEnableFields();
    begin
        CDCHasDCDocument := HasDocumentsGenJnlLine(Rec);
    end;

    local procedure HasDocumentsGenJnlLine(GenJnlLine: record "Gen. Journal Line"): Boolean
    var
        Doc: Record "CDC Document";
        PurchCrMemoHdr: record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        PreAssNo: Code[20];
        DocType: Integer;

    begin

        PreAssNo := '';
        case GenJnlLine."Applies-to Doc. Type" of
            GenJnlLine."Applies-to Doc. Type"::Invoice:
                begin
                    DocType := 2;
                    if PurchInvHeader.GET(GenJnlLine."Applies-to Doc. No.") then
                        PreAssNo := PurchInvHeader."Pre-Assigned No.";
                end;
            GenJnlLine."Applies-to Doc. Type"::"Credit Memo":
                begin
                    DocType := 3;
                    if PurchCrMemoHdr.GET(GenJnlLine."Applies-to Doc. No.") then
                        PreAssNo := PurchCrMemoHdr."Pre-Assigned No.";
                end;
            else
                exit(false);
        end;

        Doc.SETCURRENTKEY("Created Doc. Table No.", "Created Doc. Subtype", "Created Doc. No.", "Created Doc. Ref. No.");
        Doc.SETRANGE("Created Doc. Table No.", DATABASE::"Purchase Header");
        Doc.SETRANGE("Created Doc. Subtype", DocType);
        Doc.SETRANGE("Created Doc. No.", PreAssNo);
        Doc.SETFILTER("File Type", '%1|%2', Doc."File Type"::OCR, Doc."File Type"::XML);
        exit(not Doc.ISEMPTY);

    end;

    local procedure CDCCheckIfHasAccess()
    var
        CDCLicenseMgt: Codeunit "CDC Continia License Mgt.";
    begin
        CDCHasAccess := CDCLicenseMgt.HasAccessToDC();
    end;

}