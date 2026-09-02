import 'package:flutter/material.dart';

enum WikiCategory {
  userManual(
    id: 'user_manual',
    title: 'Руководство пользователя',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF4CAF50),
    description: 'Пошаговые инструкции от подготовки дома до отчетов в МКК',
  ),
  physiology(
    id: 'physiology',
    title: 'Физиология и калории',
    icon: Icons.science_rounded,
    color: Color(0xFFFF9800),
    description: 'Формулы BMR, PAL, расчет БЖУ, воды, соли и расхода газа',
  ),
  food(
    id: 'food',
    title: 'Продуктовая раскладка',
    icon: Icons.restaurant_rounded,
    color: Color(0xFFE91E63),
    description: 'База из 57 продуктов, калорийная плотность и меню по дням',
  ),
  gear(
    id: 'gear',
    title: 'Снаряжение и развесовка',
    icon: Icons.backpack_rounded,
    color: Color(0xFF2196F3),
    description: '66 предметов, деление группового веса и зимний комплект',
  ),
  navigation(
    id: 'navigation',
    title: 'Карты, GPS и трекинг',
    icon: Icons.map_rounded,
    color: Color(0xFF00BCD4),
    description: 'Импорт GPX, офлайн-тайлы, метки и вечерний дебрифинг',
  ),
  mkk(
    id: 'mkk',
    title: 'МКК и спортивный туризм',
    icon: Icons.assignment_rounded,
    color: Color(0xFF9C27B0),
    description: 'Маршрутная книжка, техническое описание ФСТР и архивы',
  ),
  firstAid(
    id: 'first_aid',
    title: 'Первая помощь и медицина',
    icon: Icons.medical_services_rounded,
    color: Color(0xFFF44336),
    description: 'Неотложные состояния, травмы, горная болезнь, укусы и аптечка',
  ),
  faq(
    id: 'faq',
    title: 'FAQ и решение проблем',
    icon: Icons.help_outline_rounded,
    color: Color(0xFF607D8B),
    description: 'Частые вопросы, батарея на морозе, калибровка датчиков',
  );

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  const WikiCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });
}
