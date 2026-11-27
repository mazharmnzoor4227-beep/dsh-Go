import 'dart:ui' show CheckedState, Tristate;

import 'package:dsh_app/ui/chat/widgets/question_card.dart';
import 'package:dsh_client/dsh_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

const request = UserQuestionRequest(
  eventId: 'q1',
  sessionId: 's1',
  questions: [
    UserQuestion(
      id: 'db',
      question: 'Database',
      options: [QuestionOption('PostgreSQL', null), QuestionOption('SQLite', null)],
    ),
  ],
);

void main() {
  setUpAll(loadTestFonts);
  testWidgets('selection and custom text survive scrolling and route remount', (tester) async {
    usePhoneView(tester);
    final bucket = PageStorageBucket();
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    List<QuestionAnswer>? answers;
    Widget page({bool show = true}) => testApp(
      Scaffold(
        body: PageStorage(
          bucket: bucket,
          child: show
              ? ListView.builder(
                  controller: scroll,
                  reverse: true,
                  itemCount: 31,
                  itemBuilder: (_, i) => i == 0
                      ? QuestionCard(
                          request: request,
                          onAnswer: (_, value) async {
                            answers = value;
                          },
                        )
                      : SizedBox(height: 90, child: Text('Message $i')),
                )
              : const SizedBox(),
        ),
      ),
    );
    await tester.pumpWidget(page());
    await tester.tap(find.text('PostgreSQL'));
    await tester.tap(find.text('Other answer'));
    await pumpFrames(tester, 4);
    await tester.enterText(find.byType(TextField), 'Extra note');
    FocusManager.instance.primaryFocus?.unfocus();
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    scroll.jumpTo(0);
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Extra note');
    await tester.pumpWidget(page(show: false));
    await tester.pumpWidget(page());
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Extra note');
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(answers!.single.selected, ['PostgreSQL']);
    expect(answers!.single.custom, 'Extra note');
  });
  testWidgets('a question that arrives in Chinese is never shown in Chinese', (tester) async {
    const chineseRequest = UserQuestionRequest(
      eventId: 'q2',
      sessionId: 's1',
      questions: [
        UserQuestion(
          id: 'install',
          question: '是否安装 Antigravity CLI？',
          options: [QuestionOption('是', null), QuestionOption('否', null)],
        ),
      ],
    );
    await tester.pumpWidget(
      testApp(
        Scaffold(body: QuestionCard(request: chineseRequest, onAnswer: (_, _) async {})),
      ),
    );
    expect(find.text('是否安装 Antigravity CLI？'), findsNothing);
    expect(find.text('是'), findsNothing);
    expect(find.textContaining('The assistant asked a question in Chinese'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
  testWidgets('single choice exposes checked, exclusive, enabled and tap semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: QuestionCard(request: request, onAnswer: (_, _) async {}),
        ),
      ),
    );
    await tester.tap(find.text('PostgreSQL'));
    await tester.pump();
    final node = tester.getSemantics(find.text('PostgreSQL'));
    final flags = node.flagsCollection;
    expect(flags.isChecked, CheckedState.isTrue);
    expect(flags.isInMutuallyExclusiveGroup, isTrue);
    expect(flags.isEnabled, Tristate.isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();
  });
}
