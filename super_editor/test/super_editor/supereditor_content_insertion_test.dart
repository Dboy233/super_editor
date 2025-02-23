import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';

import 'package:super_editor/src/test/super_editor_test/supereditor_inspector.dart';
import 'package:super_editor/src/test/super_editor_test/supereditor_robot.dart';
import 'package:super_editor/super_editor.dart';

import '../test_tools.dart';
import 'supereditor_test_tools.dart';

void main() {
  group('SuperEditor', () {
    group('inserts an image', () {
      testWidgetsOnAllPlatforms('when the selection sits at the beginning of a non-empty paragraph', (tester) async {
        // Pump a widget with an arbitrary size for the images.
        final context = await tester //
            .createDocument()
            .fromMarkdown("First paragraph")
            .withAddedComponents(
          [const FakeImageComponentBuilder(size: Size(100, 100))],
        ).pump();

        // Place caret at the beginning of the paragraph.
        await tester.placeCaretInParagraph(context.findEditContext().document.nodes.first.id, 0);

        // Insert the image at the current selection.
        context.findEditContext().commonOps.insertImage('http://image.fake');
        await tester.pumpAndSettle();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that one node was inserted.
        expect(doc.nodes.length, 2);

        // Ensure that the image was added.
        expect(doc.nodes[0], isA<ImageNode>());

        // Ensure that the paragraph node content remains unchanged, but is moved down.
        expect(doc.nodes[1], isA<ParagraphNode>());
        expect((doc.nodes[1] as ParagraphNode).text.text, 'First paragraph');

        // Ensure the selection was placed at the beginning of the paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes[1].id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });
      testWidgetsOnAllPlatforms('when the selection sits at the middle of a paragraph', (tester) async {
        // Pump a widget with an arbitrary size for the images.
        final context = await tester //
            .createDocument()
            .fromMarkdown("Before the image after the image")
            .withAddedComponents(
          [const FakeImageComponentBuilder(size: Size(100, 100))],
        ).pump();

        // Place caret at "Before the image| after the image".
        await tester.placeCaretInParagraph(context.findEditContext().document.nodes.first.id, 16);

        // Insert the image at the current selection.
        context.findEditContext().commonOps.insertImage('http://image.fake');
        await tester.pump();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that two nodes were inserted.
        expect(doc.nodes.length, 3);

        // Ensure that the first node has the text from before the caret.
        expect(doc.nodes[0], isA<ParagraphNode>());
        expect((doc.nodes[0] as ParagraphNode).text.text, 'Before the image');

        // Ensure that the image was added.
        expect(doc.nodes[1], isA<ImageNode>());

        // Ensure that the last node has the text from after the caret.
        expect(doc.nodes[2], isA<ParagraphNode>());
        expect((doc.nodes[2] as ParagraphNode).text.text, ' after the image');

        // Ensure the selection was placed at the beginning of the last paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes.last.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms('when a downstream selection sits at the end of a paragraph', (tester) async {
        // Pump a widget with an arbitrary size for the images.
        final context = await tester //
            .createDocument()
            .fromMarkdown("First paragraph")
            .withAddedComponents(
          [const FakeImageComponentBuilder(size: Size(100, 100))],
        ).pump();

        // Place caret at the end of the paragraph.
        await tester.placeCaretInParagraph(context.findEditContext().document.nodes.first.id, 15);

        // Insert the image at the current selection.
        context.findEditContext().commonOps.insertImage('http://image.fake');
        await tester.pumpAndSettle();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that two nodes were inserted.
        expect(doc.nodes.length, 3);

        // Ensure that the first node remains unchanged.
        expect(doc.nodes[0], isA<ParagraphNode>());
        expect((doc.nodes[0] as ParagraphNode).text.text, 'First paragraph');

        // Ensure that the image was added.
        expect(doc.nodes[1], isA<ImageNode>());

        // Ensure that an empty node was added after the image.
        expect(doc.nodes[2], isA<ParagraphNode>());
        expect((doc.nodes[2] as ParagraphNode).text.text, '');

        // Ensure the selection was placed at the beginning of the last paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes.last.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms('when an upstream selection sits at the end of a paragraph', (tester) async {
        // Pump a widget with an arbitrary size for the images.
        final context = await tester //
            .createDocument()
            .fromMarkdown("""First paragraph
            
Second paragraph"""). //
            withAddedComponents(
          [const FakeImageComponentBuilder(size: Size(100, 100))],
        ).pump();

        // Place caret at the end of the first paragraph by selecting the second paragraph and pressing left.
        //
        // This results in an upstream text affinity.
        await tester.placeCaretInParagraph(context.findEditContext().document.nodes.last.id, 0);
        await tester.pressLeftArrow();

        // Insert the image at the current selection.
        context.findEditContext().commonOps.insertImage('http://image.fake');
        await tester.pumpAndSettle();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that two nodes were inserted.
        expect(doc.nodes.length, 4);

        // Ensure that the first node remains unchanged.
        expect(doc.nodes[0], isA<ParagraphNode>());
        expect((doc.nodes[0] as ParagraphNode).text.text, 'First paragraph');

        // Ensure that the image was added.
        expect(doc.nodes[1], isA<ImageNode>());

        // Ensure that an empty node was added after the image.
        expect(doc.nodes[2], isA<ParagraphNode>());
        expect((doc.nodes[2] as ParagraphNode).text.text, '');

        // Ensure the selection was placed at the beginning of the newly created paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes[2].id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms('when the selection sits at an empty paragraph', (tester) async {
        // Pump a widget with an arbitrary size for the images.
        final context = await tester //
            .createDocument()
            .withSingleEmptyParagraph()
            .withAddedComponents(
          [const FakeImageComponentBuilder(size: Size(100, 100))],
        ).pump();

        // Place caret at the empty paragraph.
        await tester.placeCaretInParagraph("1", 0);

        // Insert the image at the current selection.
        context.findEditContext().commonOps.insertImage('http://image.fake');
        await tester.pumpAndSettle();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that one node was inserted.
        expect(doc.nodes.length, 2);

        // Ensure that the paragraph was converted to an image.
        expect(doc.nodes.first, isA<ImageNode>());

        // Ensure that an empty node was added after the image.
        expect(doc.nodes[1], isA<ParagraphNode>());
        expect((doc.nodes[1] as ParagraphNode).text.text, '');

        // Ensure the selection was placed at the empty paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes[1].id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });
    });

    group('inserts a horizontal rule', () {
      testWidgetsOnAllPlatforms('when the selection sits at the beginning of a non-empty paragraph', (tester) async {
        final context = await tester //
            .createDocument()
            .fromMarkdown("First paragraph")
            .pump();

        // Place caret at the beginning of the paragraph.
        await tester.placeCaretInParagraph(context.findEditContext().document.nodes.first.id, 0);

        // Insert the horizontal rule at the current selection.
        context.findEditContext().commonOps.insertHorizontalRule();
        await tester.pumpAndSettle();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that one node was inserted.
        expect(doc.nodes.length, 2);

        // Ensure that the horizontal rule was added.
        expect(doc.nodes[0], isA<HorizontalRuleNode>());

        // Ensure that the paragraph node content remains unchanged, but is moved down.
        expect(doc.nodes[1], isA<ParagraphNode>());
        expect((doc.nodes[1] as ParagraphNode).text.text, 'First paragraph');

        // Ensure the selection was placed at the beginning of the paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes[1].id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });
      testWidgetsOnAllPlatforms('when the selection sits at the middle of a paragraph', (tester) async {
        final context = await tester //
            .createDocument()
            .fromMarkdown("Before the hr after the hr")
            .pump();

        // Place caret at "Before the hr| after the hr".
        await tester.placeCaretInParagraph(context.findEditContext().document.nodes.first.id, 13);

        // Insert the horizontal rule at the current selection.
        context.findEditContext().commonOps.insertHorizontalRule();
        await tester.pumpAndSettle();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that two nodes were inserted.
        expect(doc.nodes.length, 3);

        // Ensure that the first node has the text from before the caret.
        expect(doc.nodes[0], isA<ParagraphNode>());
        expect((doc.nodes[0] as ParagraphNode).text.text, 'Before the hr');

        // Ensure that the horizontal rule was added.
        expect(doc.nodes[1], isA<HorizontalRuleNode>());

        // Ensure that the last node has the text from after the caret.
        expect(doc.nodes[2], isA<ParagraphNode>());
        expect((doc.nodes[2] as ParagraphNode).text.text, ' after the hr');

        // Ensure the selection was placed at the beginning of the last paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes.last.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms('when a downstream selection sits at the end of a paragraph', (tester) async {
        final context = await tester //
            .createDocument()
            .fromMarkdown("First paragraph")
            .pump();

        // Place caret at the end of the paragraph.
        await tester.placeCaretInParagraph(context.findEditContext().document.nodes.first.id, 15);

        // Insert the horizontal rule at the current selection.
        context.findEditContext().commonOps.insertHorizontalRule();
        await tester.pumpAndSettle();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that two nodes were inserted.
        expect(doc.nodes.length, 3);

        // Ensure that the first node remains unchanged.
        expect(doc.nodes[0], isA<ParagraphNode>());
        expect((doc.nodes[0] as ParagraphNode).text.text, 'First paragraph');

        // Ensure that the horizontal rule was added.
        expect(doc.nodes[1], isA<HorizontalRuleNode>());

        // Ensure that an empty node was added at the end.
        expect(doc.nodes[2], isA<ParagraphNode>());
        expect((doc.nodes[2] as ParagraphNode).text.text, '');

        // Ensure the selection was placed at the beginning of the last paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes.last.id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms('when an upstream selection sits at the end of a paragraph', (tester) async {
        final context = await tester //
            .createDocument()
            .fromMarkdown("""First paragraph
            
 Second paragraph""") //
            .pump();

        // Place caret at the end of the first paragraph by selecting the second paragraph and pressing left.
        //
        // This results in an upstream text affinity.
        await tester.placeCaretInParagraph(context.findEditContext().document.nodes.last.id, 0);
        await tester.pressLeftArrow();

        // Insert the horizontal rule at the current selection.
        context.findEditContext().commonOps.insertHorizontalRule();
        await tester.pumpAndSettle();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that two nodes were inserted.
        expect(doc.nodes.length, 4);

        // Ensure that the first node remains unchanged.
        expect(doc.nodes[0], isA<ParagraphNode>());
        expect((doc.nodes[0] as ParagraphNode).text.text, 'First paragraph');

        // Ensure that the horizontal rule was added.
        expect(doc.nodes[1], isA<HorizontalRuleNode>());

        // Ensure that an empty node was added at the end.
        expect(doc.nodes[2], isA<ParagraphNode>());
        expect((doc.nodes[2] as ParagraphNode).text.text, '');

        // Ensure the selection was placed at the beginning of the newly created paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes[2].id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms('when the selection sits at an empty paragraph', (tester) async {
        final context = await tester //
            .createDocument()
            .withSingleEmptyParagraph()
            .pump();

        // Place caret at the empty paragraph.
        await tester.placeCaretInParagraph("1", 0);

        // Insert the horizontal rule at the current selection.
        context.findEditContext().commonOps.insertHorizontalRule();
        await tester.pumpAndSettle();

        final doc = SuperEditorInspector.findDocument()!;

        // Ensure that one node was inserted.
        expect(doc.nodes.length, 2);

        // Ensure the paragraph was converted to a horizontal rule.
        expect(doc.nodes.first, isA<HorizontalRuleNode>());

        // Ensure that an empty node was added after the horizontal rule.
        expect(doc.nodes[1], isA<ParagraphNode>());
        expect((doc.nodes[1] as ParagraphNode).text.text, '');

        // Ensure that the selection was placed at the empty paragraph.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: doc.nodes[1].id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });
    });

    group('inserts a paragraph', () {
      testWidgetsOnDesktop('when the user presses ENTER at the end of an image', (tester) async {
        final testContext = await tester
            .createDocument()
            .withCustomContent(
              MutableDocument(
                nodes: [
                  ImageNode(
                    id: "img-node",
                    imageUrl: 'https://this.is.a.fake.image',
                    metadata: const SingleColumnLayoutComponentStyles(
                      width: double.infinity,
                    ).toMetadata(),
                  ),
                  ParagraphNode(
                    id: 'text-node',
                    text: AttributedText('Paragraph'),
                  ),
                ],
              ),
            )
            .withAddedComponents([const FakeImageComponentBuilder(size: Size(100, 100))])
            .withEditorSize(const Size(300, 300))
            .pump();

        // Place caret after the image by selecting the beginning of the paragraph and pressing left.
        await tester.placeCaretInParagraph('text-node', 0);
        await tester.pressLeftArrow();

        // Ensure the selection was placed at the end of the image.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: 'img-node',
              nodePosition: UpstreamDownstreamNodePosition.downstream(),
            ),
          ),
        );

        // Simulate pressing enter on a hardware keyboard.
        await tester.pressEnter();

        // Ensure an empty paragraph was inserted and the selection was placed on its beginning.
        final doc = testContext.findEditContext().document;
        expect(doc.nodes.length, 3);
        expect(doc.nodes[1], isA<ParagraphNode>());
        expect((doc.nodes[1] as ParagraphNode).text.text, '');
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: testContext.findEditContext().document.nodes[1].id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });

      testWidgetsOnAndroid(
          'when the user presses the newline button on the software keyboard at the end of an image (on Android)',
          (tester) async {
        final testContext = await tester
            .createDocument()
            .withCustomContent(
              MutableDocument(
                nodes: [
                  ImageNode(
                    id: "img-node",
                    imageUrl: 'https://this.is.a.fake.image',
                    metadata: const SingleColumnLayoutComponentStyles(
                      width: double.infinity,
                    ).toMetadata(),
                  ),
                  ParagraphNode(
                    id: 'text-node',
                    text: AttributedText('Paragraph'),
                  ),
                ],
              ),
            )
            .withAddedComponents([const FakeImageComponentBuilder(size: Size(100, 100))])
            .withEditorSize(const Size(300, 300))
            .pump();

        // Place caret at the beginning of the paragraph.
        await tester.placeCaretInParagraph('text-node', 0);
        await tester.pressLeftArrow();

        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: 'img-node',
              nodePosition: UpstreamDownstreamNodePosition.downstream(),
            ),
          ),
        );

        // On Android, pressing ENTER generates a "\n" insertion.
        await tester.typeImeText('\n');

        // Ensure an empty paragraph was inserted and the selection was placed on its beginning.
        final doc = testContext.findEditContext().document;
        expect(doc.nodes.length, 3);
        expect(doc.nodes[1], isA<ParagraphNode>());
        expect((doc.nodes[1] as ParagraphNode).text.text, '');
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: testContext.findEditContext().document.nodes[1].id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });

      testWidgetsOnIos(
          'when the user presses the newline button on the software keyboard at the end of an image (on iOS)',
          (tester) async {
        final testContext = await tester
            .createDocument()
            .withCustomContent(
              MutableDocument(
                nodes: [
                  ImageNode(
                    id: "img-node",
                    imageUrl: 'https://this.is.a.fake.image',
                    metadata: const SingleColumnLayoutComponentStyles(
                      width: double.infinity,
                    ).toMetadata(),
                  ),
                  ParagraphNode(
                    id: 'text-node',
                    text: AttributedText('Paragraph'),
                  ),
                ],
              ),
            )
            .withAddedComponents([const FakeImageComponentBuilder(size: Size(100, 100))])
            .withEditorSize(const Size(300, 300))
            .pump();

        // Place caret at the beginning of the paragraph.
        await tester.placeCaretInParagraph('text-node', 0);
        await tester.pressLeftArrow();

        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: 'img-node',
              nodePosition: UpstreamDownstreamNodePosition.downstream(),
            ),
          ),
        );

        // On iOS, pressing ENTER generates a newline action.
        await tester.testTextInput.receiveAction(TextInputAction.newline);
        await tester.pump();

        // Ensure an empty paragraph was inserted and the selection was placed on its beginning.
        final doc = testContext.findEditContext().document;
        expect(doc.nodes.length, 3);
        expect(doc.nodes[1], isA<ParagraphNode>());
        expect((doc.nodes[1] as ParagraphNode).text.text, '');
        expect(
          SuperEditorInspector.findDocumentSelection(),
          DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: testContext.findEditContext().document.nodes[1].id,
              nodePosition: const TextNodePosition(offset: 0),
            ),
          ),
        );
      });
    });
  });
}
