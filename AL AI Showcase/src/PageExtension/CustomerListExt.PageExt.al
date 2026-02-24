namespace BWPA.ALAIShowcase;

/// <summary>
/// Extends the Customer List page with a welcome message.
/// This is the initial sample code from the AL-Go CreateApp workflow.
/// </summary>
pageextension 50100 CustomerListExt extends "Customer List"
{
    trigger OnOpenPage()
    begin
        Message('App published: Hello world');
    end;
}
