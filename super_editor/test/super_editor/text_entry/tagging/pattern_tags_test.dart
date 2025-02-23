import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../test_tools.dart';
import '../../supereditor_test_tools.dart';
import '../../test_documents.dart';

void main() {
  group("SuperEditor pattern tags >", () {
    group("composing >", () {
      testWidgetsOnAllPlatforms("doesn't attribute a single #", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );
        await tester.placeCaretInParagraph("1", 0);

        // Insert a single "#".
        await tester.typeImeText("#");

        // Ensure that no hash tag was created.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "#");
        expect(
          text.hasAttributionAt(0, attribution: const PatternTagAttribution()),
          isFalse,
        );
      });

      testWidgetsOnAllPlatforms("can start at the beginning of a paragraph", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );
        await tester.placeCaretInParagraph("1", 0);

        // Compose a pattern tag.
        await tester.typeImeText("#flutter");

        // Ensure that the tag has a composing attribution.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "#flutter");
        expect(
          text.getAttributedRange({const PatternTagAttribution()}, 0),
          const SpanRange(start: 0, end: 7),
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

        // Place the caret at "before |".
        await tester.placeCaretInParagraph("1", 7);

        // Compose a pattern tag.
        await tester.typeImeText("#flutter");

        // Ensure that the tag has a composing attribution.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before #flutter after");
        expect(
          text.getAttributedRange({const PatternTagAttribution()}, 7),
          const SpanRange(start: 7, end: 14),
        );
      });

      testWidgetsOnAllPlatforms("removes tag when deleting back to the #", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );
        await tester.placeCaretInParagraph("1", 0);

        // Compose a pattern tag.
        await tester.typeImeText("#flutter");

        // Delete all the way back to the "#".
        await tester.pressBackspace();
        await tester.pressBackspace();
        await tester.pressBackspace();
        await tester.pressBackspace();
        await tester.pressBackspace();
        await tester.pressBackspace();
        await tester.pressBackspace();

        // Ensure that the tag doesn't have a composing attribution.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "#");
        expect(
          text.hasAttributionAt(0, attribution: const PatternTagAttribution()),
          isFalse,
        );
      });

      testWidgetsOnAllPlatforms("does not continue after a space", (tester) async {
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

        // Place the caret at "before |".
        await tester.placeCaretInParagraph("1", 7);

        // Compose a hash tag.
        await tester.typeImeText("#flutter after");

        // Ensure that there's no more composing attribution because the tag
        // should have been committed.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before #flutter after");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution is PatternTagAttribution,
            range: const SpanRange(start: 0, end: 18),
          ),
          {
            const AttributionSpan(
              attribution: PatternTagAttribution(),
              start: 7,
              end: 14,
            ),
          },
        );
      });

      testWidgetsOnAllPlatforms("does not continue after a period", (tester) async {
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

        // Place the caret at "before |".
        await tester.placeCaretInParagraph("1", 7);

        // Compose a hash tag with a period after it.
        await tester.typeImeText("#flutter. after");

        // Ensure that the hash tag doesn't include the period.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before #flutter. after");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution is PatternTagAttribution,
            range: const SpanRange(start: 0, end: 19),
          ),
          {
            const AttributionSpan(
              attribution: PatternTagAttribution(),
              start: 7,
              end: 14,
            ),
          },
        );
      });

      testWidgetsOnAllPlatforms("shrinks to wherever a period is added", (tester) async {
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

        // Place the caret at "before |".
        await tester.placeCaretInParagraph("1", 7);

        // Compose a hash tag.
        await tester.typeImeText("#flutterdart");

        // Insert a period between "flutter" and "dart".
        await tester.placeCaretInParagraph("1", 15);
        await tester.typeImeText(".");

        // Ensure that the hash tag shrunk to where the period was inserted.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before #flutter.dart");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution is PatternTagAttribution,
            range: const SpanRange(start: 0, end: 19),
          ),
          {
            const AttributionSpan(
              attribution: PatternTagAttribution(),
              start: 7,
              end: 14,
            ),
          },
        );
      });

      testWidgetsOnAllPlatforms("can create pattern tags back to back (no space)", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );
        await tester.placeCaretInParagraph("1", 0);

        // Compose a hash tag.
        await tester.typeImeText("hello #flutter#d");

        var text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "hello #flutter#d");
        expect(
          text.getAttributedRange({const PatternTagAttribution()}, 6),
          const SpanRange(start: 6, end: 13),
        );
        expect(
          text.getAttributedRange({const PatternTagAttribution()}, 14),
          const SpanRange(start: 14, end: 15),
        );

        // Finish the second hash tag.
        await tester.typeImeText("art");

        // Ensure that the tag has a composing attribution.
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "hello #flutter#dart");
        expect(
          text.getAttributedRange({const PatternTagAttribution()}, 6),
          const SpanRange(start: 6, end: 13),
        );
        expect(
          text.getAttributedRange({const PatternTagAttribution()}, 14),
          const SpanRange(start: 14, end: 18),
        );
      });

      testWidgetsOnAllPlatforms("can create pattern tags back to back (with a space)", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );
        await tester.placeCaretInParagraph("1", 0);

        // Compose a pattern tag.
        await tester.typeImeText("hello #flutter #dart");

        // Ensure that the tag has a composing attribution.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "hello #flutter #dart");
        expect(
          text.getAttributedRange({const PatternTagAttribution()}, 6),
          const SpanRange(start: 6, end: 13),
        );
        expect(
          text.getAttributedRange({const PatternTagAttribution()}, 15),
          const SpanRange(start: 15, end: 19),
        );
      });
    });

    group("caret placement >", () {
      testWidgetsOnAllPlatforms("doesn't prevent user from tapping to place caret in tag", (tester) async {
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

        // Place the caret at "before |".
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a hash tag.
        await tester.typeImeText("#flutter after");

        // Tap near the end of the tag.
        await tester.placeCaretInParagraph("1", 10);

        // Ensure that the caret was placed where tapped.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 10),
            ),
          ),
        );

        // Tap near the beginning of the tag.
        await tester.placeCaretInParagraph("1", 8);

        // Ensure that the caret was placed where tapped.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 8),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("pushes expanding downstream selection into the tag", (tester) async {
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

        // Place the caret at "before |".
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a hash tag.
        await tester.typeImeText("#flutter after");

        // Place the caret at "befor|e #flutter after".
        await tester.placeCaretInParagraph("1", 5);

        // Expand downstream until we push one character into the tag.
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();

        // Ensure that the extent was pushed into the tag.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 5),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 8),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("pushes expanding upstream selection into the tag", (tester) async {
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

        // Place the caret at "before |".
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a hash tag.
        await tester.typeImeText("#flutter after");

        // Place the caret at "before #flutter a|fter".
        await tester.placeCaretInParagraph("1", 14);

        // Expand upstream until we push one character into the tag.
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();

        // Ensure that the extent was pushed into the tag.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 14),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 11),
            ),
          ),
        );
      });
    });

    group("editing >", () {
      testWidgetsOnAllPlatforms("user can delete pieces of tags", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );
        await tester.placeCaretInParagraph("1", 0);

        // Compose a pattern tag.
        await tester.typeImeText("#abcdefghij ");

        // Delete part of the end.
        await tester.placeCaretInParagraph("1", 11);
        await tester.pressBackspace();

        // Delete part of the middle.
        await tester.placeCaretInParagraph("1", 6);
        await tester.pressBackspace();

        // Delete part of the beginning.
        await tester.placeCaretInParagraph("1", 2);
        await tester.pressBackspace();

        // Ensure that the tag is still marked as a hash tag.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "#bcdfghi ");
        expect(
          text.getAttributedRange({const PatternTagAttribution()}, 0),
          const SpanRange(start: 0, end: 7),
        );
      });
    });
  });
}

Future<TestDocumentContext> _pumpTestEditor(WidgetTester tester, MutableDocument document) async {
  return await tester //
      .createDocument()
      .withCustomContent(document)
      .withPlugin(PatternTagPlugin(
        tagRule: hashTagRule,
      ))
      .pump();
}
