namespace BWPA.ALAIShowcase.Test;

/// <summary>
/// Tests for the CustomerListExt page extension.
/// Verifies the welcome message is displayed when the Customer List is opened.
/// </summary>
codeunit 50250 "Customer List Ext. Test"
{
    Subtype = Test;

    [Test]
    [HandlerFunctions('HelloWorldMessageHandler')]
    procedure CustomerListOpen_WhenPageOpens_ShowsWelcomeMessage()
    var
        CustList: TestPage "Customer List";
    begin
        // [GIVEN] The Customer List page with CustomerListExt extension installed

        // [WHEN] The page is opened
        CustList.OpenView();
        CustList.Close();

        // [THEN] The welcome message should have been displayed
        if not MessageDisplayed then
            Error(
                'CustomerListOpen_WhenPageOpens_ShowsWelcomeMessage failed: ' +
                'Expected Message "App published: Hello world" to be displayed but it was not. ' +
                'Object: Customer List Ext. Test, Procedure: CustomerListOpen_WhenPageOpens_ShowsWelcomeMessage. ' +
                'Fix: Verify CustomerListExt.OnOpenPage trigger contains the Message call.'
            );
    end;

    [MessageHandler]
    procedure HelloWorldMessageHandler(Message: Text[1024])
    begin
        MessageDisplayed := MessageDisplayed or (Message = 'App published: Hello world');
    end;

    var
        MessageDisplayed: Boolean;
}
