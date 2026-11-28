-- MathMind skill catalog. Run after schema.sql.
-- Three kinds of skills:
--   NC / FL : state standards (NC Standard Course of Study, Florida B.E.S.T.).
--   CORE    : MathMind extensions from the Russian school (equations, divisibility, bar models ...),
--             taught ahead of or beside the state program.
--   OLY     : olympiad techniques (Math Kangaroo style).
-- NOTE for the methodist: titles are short summaries. Check codes and wording against the
-- official state documents before showing them to parents; edit here or in the admin panel.

insert into skills (id, framework, grade, domain, title_en, title_ru, sort) values
-- ---------------- North Carolina, grade 3 ----------------
('NC.3.OA.1', 'NC', 3, 'Operations & Algebraic Thinking', 'Meaning of multiplication (equal groups, arrays)', 'Смысл умножения: равные группы, массивы', 101),
('NC.3.OA.2', 'NC', 3, 'Operations & Algebraic Thinking', 'Meaning of division (sharing, grouping)', 'Смысл деления: поровну и по группам', 102),
('NC.3.OA.3', 'NC', 3, 'Operations & Algebraic Thinking', 'Multiplication and division word problems within 100', 'Задачи на умножение и деление в пределах 100', 103),
('NC.3.OA.6', 'NC', 3, 'Operations & Algebraic Thinking', 'Division as an unknown-factor problem', 'Деление как поиск неизвестного множителя', 104),
('NC.3.OA.7', 'NC', 3, 'Operations & Algebraic Thinking', 'Multiplication facts and division within 100', 'Таблица умножения и деления до 100', 105),
('NC.3.OA.8', 'NC', 3, 'Operations & Algebraic Thinking', 'Two-step word problems (four operations)', 'Задачи в два действия', 106),
('NC.3.OA.9', 'NC', 3, 'Operations & Algebraic Thinking', 'Arithmetic patterns', 'Закономерности в числах', 107),
('NC.3.NBT.2', 'NC', 3, 'Number & Operations in Base Ten', 'Add and subtract within 1,000', 'Сложение и вычитание в пределах 1000', 111),
('NC.3.NBT.3', 'NC', 3, 'Number & Operations in Base Ten', 'Multiply by multiples of 10 (e.g. 8 × 60)', 'Умножение на круглые десятки (8 × 60)', 112),
('NC.3.NF.1', 'NC', 3, 'Fractions', 'Understand fractions (unit fractions, a/b)', 'Понятие дроби', 121),
('NC.3.NF.2', 'NC', 3, 'Fractions', 'Fractions on a number line', 'Дроби на числовой прямой', 122),
('NC.3.NF.3', 'NC', 3, 'Fractions', 'Equivalent fractions', 'Равные дроби', 123),
('NC.3.NF.4', 'NC', 3, 'Fractions', 'Compare fractions', 'Сравнение дробей', 124),
('NC.3.MD.1', 'NC', 3, 'Measurement & Data', 'Time to the minute, elapsed time', 'Время до минуты, сколько прошло времени', 131),
('NC.3.MD.2', 'NC', 3, 'Measurement & Data', 'Liquid volume and mass', 'Объём и масса', 132),
('NC.3.MD.3', 'NC', 3, 'Measurement & Data', 'Picture graphs and bar graphs', 'Пиктограммы и столбчатые диаграммы', 133),
('NC.3.MD.4', 'NC', 3, 'Measurement & Data', 'Measure lengths, line plots', 'Измерение длины, линейные графики', 134),
('NC.3.MD.5', 'NC', 3, 'Measurement & Data', 'Area: concept and unit squares', 'Площадь: понятие, единичные квадраты', 135),
('NC.3.MD.7', 'NC', 3, 'Measurement & Data', 'Area and multiplication', 'Площадь и умножение', 136),
('NC.3.MD.8', 'NC', 3, 'Measurement & Data', 'Perimeter', 'Периметр', 137),
('NC.3.G.1',  'NC', 3, 'Geometry', 'Quadrilaterals and their attributes', 'Четырёхугольники и их свойства', 141),

-- ---------------- Florida B.E.S.T., grade 4 ----------------
('MA.4.NSO.1.1', 'FL', 4, 'Number Sense & Operations', 'Place value up to 1,000,000', 'Разряды до миллиона', 201),
('MA.4.NSO.1.2', 'FL', 4, 'Number Sense & Operations', 'Read and write multi-digit numbers', 'Чтение и запись многозначных чисел', 202),
('MA.4.NSO.1.3', 'FL', 4, 'Number Sense & Operations', 'Compare and order multi-digit numbers', 'Сравнение многозначных чисел', 203),
('MA.4.NSO.1.4', 'FL', 4, 'Number Sense & Operations', 'Rounding', 'Округление', 204),
('MA.4.NSO.1.5', 'FL', 4, 'Number Sense & Operations', 'Decimals to hundredths: plot, compare', 'Десятичные дроби до сотых', 205),
('MA.4.NSO.2.1', 'FL', 4, 'Number Sense & Operations', 'Multiplication and division facts with automaticity', 'Таблица умножения на автомате', 211),
('MA.4.NSO.2.2', 'FL', 4, 'Number Sense & Operations', 'Multiply up to 3-digit by 2-digit', 'Умножение многозначного на двузначное', 212),
('MA.4.NSO.2.3', 'FL', 4, 'Number Sense & Operations', 'Multiply 2-digit by 2-digit fluently', 'Умножение двузначных чисел', 213),
('MA.4.NSO.2.4', 'FL', 4, 'Number Sense & Operations', 'Divide up to 4-digit by 1-digit, remainders', 'Деление на однозначное, остаток', 214),
('MA.4.NSO.2.5', 'FL', 4, 'Number Sense & Operations', 'Multiply by multiples of 10, 100, 1000', 'Умножение на 10, 100, 1000 и круглые числа', 215),
('MA.4.NSO.2.6', 'FL', 4, 'Number Sense & Operations', 'Mental math with 10, 100, 1000', 'Устный счёт с 10, 100, 1000', 216),
('MA.4.NSO.2.7', 'FL', 4, 'Number Sense & Operations', 'Add and subtract decimals', 'Сложение и вычитание десятичных дробей', 217),
('MA.4.FR.1.1', 'FL', 4, 'Fractions', 'Fractions and decimals: tenths and hundredths', 'Дроби и десятичные: десятые и сотые', 221),
('MA.4.FR.1.2', 'FL', 4, 'Fractions', 'Decimal and fraction notation', 'Запись дроби десятичной и обычной', 222),
('MA.4.FR.1.3', 'FL', 4, 'Fractions', 'Equivalent fractions', 'Равные дроби', 223),
('MA.4.FR.1.4', 'FL', 4, 'Fractions', 'Compare fractions', 'Сравнение дробей', 224),
('MA.4.FR.2.1', 'FL', 4, 'Fractions', 'Decompose a fraction', 'Разложение дроби на части', 231),
('MA.4.FR.2.2', 'FL', 4, 'Fractions', 'Add and subtract fractions, like denominators', 'Сложение и вычитание дробей с одинаковым знаменателем', 232),
('MA.4.FR.2.4', 'FL', 4, 'Fractions', 'Multiply a fraction by a whole number', 'Умножение дроби на целое число', 234),
('MA.4.AR.1.1', 'FL', 4, 'Algebraic Reasoning', 'Multiplication and division word problems, remainders', 'Задачи на умножение и деление, остатки', 241),
('MA.4.AR.1.2', 'FL', 4, 'Algebraic Reasoning', 'Fraction word problems (add, subtract)', 'Задачи на сложение и вычитание дробей', 242),
('MA.4.AR.1.3', 'FL', 4, 'Algebraic Reasoning', 'Fraction of a whole number word problems', 'Задачи на нахождение части от числа', 243),
('MA.4.AR.2.1', 'FL', 4, 'Algebraic Reasoning', 'True or false equations', 'Верные и неверные равенства', 244),
('MA.4.AR.2.2', 'FL', 4, 'Algebraic Reasoning', 'Unknown number in an equation', 'Неизвестное в уравнении', 245),
('MA.4.AR.3.1', 'FL', 4, 'Algebraic Reasoning', 'Factors, multiples, prime and composite', 'Делители, кратные, простые и составные числа', 246),
('MA.4.AR.3.2', 'FL', 4, 'Algebraic Reasoning', 'Number patterns', 'Числовые закономерности', 247),
('MA.4.M.1.1', 'FL', 4, 'Measurement', 'Measure length, volume, weight, temperature', 'Измерение величин', 251),
('MA.4.M.1.2', 'FL', 4, 'Measurement', 'Convert units (feet and inches, hours and minutes ...)', 'Перевод единиц: футы и дюймы, часы и минуты', 252),
('MA.4.M.2.1', 'FL', 4, 'Measurement', 'Elapsed time', 'Задачи на время', 253),
('MA.4.M.2.2', 'FL', 4, 'Measurement', 'Money problems, making change', 'Задачи на деньги и сдачу', 254),
('MA.4.GR.1.1', 'FL', 4, 'Geometric Reasoning', 'Angles: types and measure', 'Углы: виды и величина', 261),
('MA.4.GR.1.2', 'FL', 4, 'Geometric Reasoning', 'Measure and draw angles with a protractor', 'Измерение углов транспортиром', 262),
('MA.4.GR.1.3', 'FL', 4, 'Geometric Reasoning', 'Adding angles, unknown angle', 'Сложение углов, неизвестный угол', 263),
('MA.4.GR.2.1', 'FL', 4, 'Geometric Reasoning', 'Perimeter and area of rectangles', 'Периметр и площадь прямоугольника', 264),
('MA.4.GR.2.2', 'FL', 4, 'Geometric Reasoning', 'Area of composite figures', 'Площадь составных фигур', 265),
('MA.4.DP.1.1', 'FL', 4, 'Data Analysis', 'Collect and display data, line plots', 'Сбор и представление данных', 271),
('MA.4.DP.1.2', 'FL', 4, 'Data Analysis', 'Interpret data: mode, median, range', 'Анализ данных: мода, медиана, размах', 272),

-- ---------------- MathMind extensions (Russian school + Singapore) ----------------
('CORE.mental',    'CORE', null, 'MathMind: thinking tools', 'Mental math: magic pairs, smart order', 'Устный счёт: волшебные пары, удобный порядок', 301),
('CORE.order',     'CORE', null, 'MathMind: thinking tools', 'Order of operations and brackets', 'Порядок действий и скобки', 302),
('CORE.equations', 'CORE', null, 'MathMind: thinking tools', 'Equations (x + a = b, a(x + b) = c)', 'Уравнения', 303),
('CORE.barmodel',  'CORE', null, 'MathMind: thinking tools', 'Bar models for word problems', 'Схемы-отрезки для задач (bar model)', 304),
('CORE.partswhole','CORE', null, 'MathMind: thinking tools', 'Parts and wholes, "times as much"', 'Часть и целое, «во сколько раз больше»', 305),
('CORE.divisibility','CORE', null, 'MathMind: thinking tools', 'Divisibility rules', 'Признаки делимости', 306),
('CORE.primes',    'CORE', null, 'MathMind: thinking tools', 'Prime factors', 'Разложение на простые множители', 307),
('CORE.angles',    'CORE', null, 'MathMind: geometry', 'Angles and lines (early)', 'Углы и прямые (раньше программы)', 311),
('CORE.3d',        'CORE', null, 'MathMind: geometry', '3D shapes, nets', '3D-фигуры и развёртки', 312),
('CORE.estimate',  'CORE', null, 'MathMind: thinking tools', 'Estimate and check', 'Прикидка и проверка ответа', 313),
('CORE.words',     'CORE', null, 'MathMind: school English', 'Math words in English (Word Wall)', 'Математические слова на английском', 314),

-- ---------------- Olympiad techniques ----------------
('OLY.backwards',  'OLY', null, 'Olympiad', 'Working backwards', 'Решение с конца', 401),
('OLY.logic',      'OLY', null, 'Olympiad', 'Logic puzzles, truth and lies', 'Логические задачи', 402),
('OLY.patterns',   'OLY', null, 'Olympiad', 'Patterns and sequences', 'Закономерности и последовательности', 403),
('OLY.counting',   'OLY', null, 'Olympiad', 'Counting and combinations', 'Подсчёт вариантов', 404),
('OLY.parity',     'OLY', null, 'Olympiad', 'Even and odd reasoning', 'Чётность', 405),
('OLY.geometry',   'OLY', null, 'Olympiad', 'Geometry puzzles (cutting, matchsticks)', 'Геометрические головоломки', 406),
('OLY.spatial',    'OLY', null, 'Olympiad', 'Cubes and spatial reasoning', 'Кубики и пространственное мышление', 407),
('OLY.clocks',     'OLY', null, 'Olympiad', 'Clocks and calendars', 'Часы и календарь', 408),
('OLY.ages',       'OLY', null, 'Olympiad', 'Age and "think of a number" problems', 'Задачи на возраст и «задумал число»', 409),
('OLY.weighing',   'OLY', null, 'Olympiad', 'Balances and weighing', 'Взвешивания и весы', 410)
on conflict (id) do update set
  framework = excluded.framework, grade = excluded.grade, domain = excluded.domain,
  title_en = excluded.title_en, title_ru = excluded.title_ru, sort = excluded.sort;
