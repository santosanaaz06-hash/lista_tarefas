import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lista_tarefas/main.dart';

void main() {
  testWidgets('Tela de tarefas abre corretamente',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MainApp());

    
    await tester.pumpAndSettle();


    expect(find.text('Lista de Tarefas'), findsOneWidget);

   
    expect(find.byType(TextField), findsOneWidget);

   
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}