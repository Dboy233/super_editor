import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../test_tools.dart';
import '../../supereditor_test_tools.dart';
import '../../test_documents.dart';

void main() {
  group("SuperEditor action tags >", () {
    group("composing >", () {
      testWidgetsOnAllPlatforms("can start at the beginning of a paragraph", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );
        await tester.placeCaretInParagraph("1", 0);

        // Compose an action tag.
        await tester.typeImeText("/header");

        // Ensure that the tag has a composing attribution.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "/header");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 0),
          const SpanRange(start: 0, end: 6),
        );
      });

      testWidgetsOnAllPlatforms("can start between words", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before  after"),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag.
        await tester.typeImeText("/header");

        // Ensure that the tag has a composing attribution.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before /header after");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 13),
        );
      });

      testWidgetsOnAllPlatforms("by default does not continue after a space", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag and more content after a space.
        await tester.typeImeText("/header after");

        // Ensure that there's no more composing attribution because the tag
        // should have been submitted.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before /header after");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == actionTagComposingAttribution,
            range: const SpanRange(start: 0, end: 18),
          ),
          isEmpty,
        );
        expect(
          text.getAttributedRange({actionTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );
      });

      testWidgetsOnAllPlatforms("can be configured to continue after a space", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
          const TagRule(trigger: "/"),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag.
        await tester.typeImeText("/header");

        // Ensure that we started a composing tag before adding a space.
        var text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before /header");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 13),
        );

        await tester.typeImeText(" after");

        // Ensure that the composing attribution continues after the space.
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before /header after");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 19),
        );
      });

      testWidgetsOnAllPlatforms("can be configured to use a different trigger", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
          const TagRule(trigger: "@", excludedCharacters: {" "}),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag.
        await tester.typeImeText("@john");

        // Ensure that we're composing an action tag.
        var text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @john");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 11),
        );
      });

      testWidgetsOnAllPlatforms("continues when user expands the selection upstream", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(""),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag.
        await tester.typeImeText("/header");

        // Expand the selection to "before /heade|r|"
        await tester.pressShiftLeftArrow();
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 14),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 13),
            ),
          ),
        );

        // Ensure we're still composing
        AttributedText text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 13),
        );

        // Expand the selection to "before |/header|"
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();

        // Ensure we're still composing
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 13),
        );

        // Expand the selection to "befor|e /header|"
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();

        // Ensure we're still composing
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 13),
        );
      });

      testWidgetsOnAllPlatforms("continues when user expands the selection downstream", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before  after"),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret at "before | after"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag.
        await tester.typeImeText("/header");

        // Move the caret to "before /|header".
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();

        // Expand the selection to "before /|header a|fter"
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 8),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 16),
            ),
          ),
        );

        // Ensure we're still composing
        AttributedText text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 13),
        );
      });

      testWidgetsOnAllPlatforms("cancels when the user moves the caret", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag.
        await tester.typeImeText("/header");

        // Move the selection somewhere else.
        await tester.placeCaretInParagraph("2", 0);
        expect(
          SuperEditorInspector.findDocumentSelection()!.extent,
          const DocumentPosition(
            nodeId: "2",
            nodePosition: TextNodePosition(offset: 0),
          ),
        );

        // Ensure that the tag was submitted.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before /header");
        expect(
          text.getAttributedRange({actionTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );
      });

      testWidgetsOnAllPlatforms("cancels when upstream selection collapses outside of tag", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag
        await tester.typeImeText("/header");

        // Expand the selection to "befor|e /header|"
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();

        // Collapse the selection to the upstream position.
        await tester.pressLeftArrow();

        // Ensure that the action tag was cancelled.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before /header");
        expect(
          text.getAttributedRange({actionTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );
      });

      testWidgetsOnAllPlatforms("cancels when downstream selection collapses outside of tag", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before  after"),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret at "before | after"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag.
        await tester.typeImeText("/header");

        // Move caret to "before /|header after"
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();

        // Expand the selection to "before @|header a|fter"
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();

        // Collapse the selection to the downstream position.
        await tester.pressRightArrow();

        // Ensure that the action tag was cancelled.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before /header after");
        expect(
          text.getAttributedRange({actionTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );
      });

      testWidgetsOnAllPlatforms("cancels composing when the user presses ESC", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Start composing a tag.
        await tester.typeImeText("/");

        // Ensure that we're composing.
        var text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({actionTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );

        // Cancel composing.
        await tester.pressEscape();

        // Ensure that the composing was cancelled.
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == actionTagComposingAttribution,
            range: const SpanRange(start: 0, end: 7),
          ),
          isEmpty,
        );
        expect(
          text.getAttributedRange({actionTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );

        // Start typing again.
        await tester.typeImeText("h");

        // Ensure that we didn't start composing again.
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before /h");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == actionTagComposingAttribution,
            range: const SpanRange(start: 0, end: 8),
          ),
          isEmpty,
        );
        expect(
          text.getAttributedRange({actionTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );

        // Add a space, cause the tag to end.
        await tester.typeImeText(" ");

        // Ensure that the cancelled tag wasn't submitted, and didn't start composing again.
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before /h ");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == actionTagComposingAttribution,
            range: const SpanRange(start: 0, end: 9),
          ),
          isEmpty,
        );
        expect(
          text.getAttributedRange({actionTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );
      });
    });

    group("submissions >", () {
      testWidgetsOnAllPlatforms("at the beginning of a paragraph", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );

        // Place the caret in the empty paragraph.
        await tester.placeCaretInParagraph("1", 0);

        // Compose an action tag.
        await tester.typeImeText("/header");

        // Submit the tag.
        await tester.pressEnter();

        // Ensure that the action tag was removed after submission.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "");
      });

      testWidgetsOnAllPlatforms("after existing text", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag
        await tester.typeImeText("/header");

        // Submit the tag.
        await tester.pressEnter();

        // Ensure that the action tag was removed.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before ");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == actionTagComposingAttribution,
            range: const SpanRange(start: 0, end: 6),
          ),
          isEmpty,
        );
      });

      testWidgetsOnAllPlatforms("in the middle of text", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before  after"),
              ),
            ],
          ),
        );

        // Place the caret at "before | after"
        await tester.placeCaretInParagraph("1", 7);

        // Compose an action tag
        await tester.typeImeText("/header");

        // Submit the tag.
        await tester.pressEnter();

        // Ensure that the action tag was removed.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before  after");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == actionTagComposingAttribution,
            range: const SpanRange(start: 0, end: 12),
          ),
          isEmpty,
        );
      });
    });
  });
}

Future<TestDocumentContext> _pumpTestEditor(
  WidgetTester tester,
  MutableDocument document, [
  TagRule tagRule = defaultActionTagRule,
]) async {
  final actionTagPlugin = ActionTagsPlugin(tagRule: tagRule);

  return await tester //
      .createDocument()
      .withCustomContent(document)
      .withAddedKeyboardActions(prepend: [
        // In real apps, the app needs to decide when to submit an action tag.
        // For the purpose of tests, we'll arbitrarily choose to submit on enter.
        _submitOnEnter,
      ])
      .withPlugin(actionTagPlugin)
      .pump();
}

ExecutionInstruction _submitOnEnter({
  required SuperEditorContext editContext,
  required RawKeyEvent keyEvent,
}) {
  if (keyEvent is KeyDownEvent) {
    return ExecutionInstruction.continueExecution;
  }
  if (keyEvent.logicalKey != LogicalKeyboardKey.enter) {
    return ExecutionInstruction.continueExecution;
  }

  editContext.editor.execute([
    const SubmitComposingActionTagRequest(),
  ]);

  return ExecutionInstruction.haltExecution;
}
