// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ExercisesCacheTable extends ExercisesCache
    with TableInfo<$ExercisesCacheTable, ExercisesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyPartsMeta = const VerificationMeta(
    'bodyParts',
  );
  @override
  late final GeneratedColumn<String> bodyParts = GeneratedColumn<String>(
    'body_parts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _targetMusclesMeta = const VerificationMeta(
    'targetMuscles',
  );
  @override
  late final GeneratedColumn<String> targetMuscles = GeneratedColumn<String>(
    'target_muscles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _secondaryMusclesMeta = const VerificationMeta(
    'secondaryMuscles',
  );
  @override
  late final GeneratedColumn<String> secondaryMuscles = GeneratedColumn<String>(
    'secondary_muscles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _equipmentsMeta = const VerificationMeta(
    'equipments',
  );
  @override
  late final GeneratedColumn<String> equipments = GeneratedColumn<String>(
    'equipments',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gifUrlMeta = const VerificationMeta('gifUrl');
  @override
  late final GeneratedColumn<String> gifUrl = GeneratedColumn<String>(
    'gif_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlsMeta = const VerificationMeta(
    'imageUrls',
  );
  @override
  late final GeneratedColumn<String> imageUrls = GeneratedColumn<String>(
    'image_urls',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    bodyParts,
    targetMuscles,
    secondaryMuscles,
    equipments,
    difficulty,
    gifUrl,
    imageUrls,
    instructions,
    overview,
    isCustom,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExercisesCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('body_parts')) {
      context.handle(
        _bodyPartsMeta,
        bodyParts.isAcceptableOrUnknown(data['body_parts']!, _bodyPartsMeta),
      );
    }
    if (data.containsKey('target_muscles')) {
      context.handle(
        _targetMusclesMeta,
        targetMuscles.isAcceptableOrUnknown(
          data['target_muscles']!,
          _targetMusclesMeta,
        ),
      );
    }
    if (data.containsKey('secondary_muscles')) {
      context.handle(
        _secondaryMusclesMeta,
        secondaryMuscles.isAcceptableOrUnknown(
          data['secondary_muscles']!,
          _secondaryMusclesMeta,
        ),
      );
    }
    if (data.containsKey('equipments')) {
      context.handle(
        _equipmentsMeta,
        equipments.isAcceptableOrUnknown(data['equipments']!, _equipmentsMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('gif_url')) {
      context.handle(
        _gifUrlMeta,
        gifUrl.isAcceptableOrUnknown(data['gif_url']!, _gifUrlMeta),
      );
    }
    if (data.containsKey('image_urls')) {
      context.handle(
        _imageUrlsMeta,
        imageUrls.isAcceptableOrUnknown(data['image_urls']!, _imageUrlsMeta),
      );
    }
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExercisesCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExercisesCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      bodyParts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_parts'],
      )!,
      targetMuscles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_muscles'],
      )!,
      secondaryMuscles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_muscles'],
      )!,
      equipments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipments'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      ),
      gifUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gif_url'],
      ),
      imageUrls: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_urls'],
      ),
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      )!,
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ExercisesCacheTable createAlias(String alias) {
    return $ExercisesCacheTable(attachedDatabase, alias);
  }
}

class ExercisesCacheData extends DataClass
    implements Insertable<ExercisesCacheData> {
  final String id;
  final String name;
  final String? category;
  final String bodyParts;
  final String targetMuscles;
  final String secondaryMuscles;
  final String equipments;
  final String? difficulty;
  final String? gifUrl;
  final String? imageUrls;
  final String instructions;
  final String? overview;
  final bool isCustom;
  final int cachedAt;
  const ExercisesCacheData({
    required this.id,
    required this.name,
    this.category,
    required this.bodyParts,
    required this.targetMuscles,
    required this.secondaryMuscles,
    required this.equipments,
    this.difficulty,
    this.gifUrl,
    this.imageUrls,
    required this.instructions,
    this.overview,
    required this.isCustom,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['body_parts'] = Variable<String>(bodyParts);
    map['target_muscles'] = Variable<String>(targetMuscles);
    map['secondary_muscles'] = Variable<String>(secondaryMuscles);
    map['equipments'] = Variable<String>(equipments);
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<String>(difficulty);
    }
    if (!nullToAbsent || gifUrl != null) {
      map['gif_url'] = Variable<String>(gifUrl);
    }
    if (!nullToAbsent || imageUrls != null) {
      map['image_urls'] = Variable<String>(imageUrls);
    }
    map['instructions'] = Variable<String>(instructions);
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  ExercisesCacheCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCacheCompanion(
      id: Value(id),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      bodyParts: Value(bodyParts),
      targetMuscles: Value(targetMuscles),
      secondaryMuscles: Value(secondaryMuscles),
      equipments: Value(equipments),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      gifUrl: gifUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(gifUrl),
      imageUrls: imageUrls == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrls),
      instructions: Value(instructions),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      isCustom: Value(isCustom),
      cachedAt: Value(cachedAt),
    );
  }

  factory ExercisesCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExercisesCacheData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      bodyParts: serializer.fromJson<String>(json['bodyParts']),
      targetMuscles: serializer.fromJson<String>(json['targetMuscles']),
      secondaryMuscles: serializer.fromJson<String>(json['secondaryMuscles']),
      equipments: serializer.fromJson<String>(json['equipments']),
      difficulty: serializer.fromJson<String?>(json['difficulty']),
      gifUrl: serializer.fromJson<String?>(json['gifUrl']),
      imageUrls: serializer.fromJson<String?>(json['imageUrls']),
      instructions: serializer.fromJson<String>(json['instructions']),
      overview: serializer.fromJson<String?>(json['overview']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'bodyParts': serializer.toJson<String>(bodyParts),
      'targetMuscles': serializer.toJson<String>(targetMuscles),
      'secondaryMuscles': serializer.toJson<String>(secondaryMuscles),
      'equipments': serializer.toJson<String>(equipments),
      'difficulty': serializer.toJson<String?>(difficulty),
      'gifUrl': serializer.toJson<String?>(gifUrl),
      'imageUrls': serializer.toJson<String?>(imageUrls),
      'instructions': serializer.toJson<String>(instructions),
      'overview': serializer.toJson<String?>(overview),
      'isCustom': serializer.toJson<bool>(isCustom),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  ExercisesCacheData copyWith({
    String? id,
    String? name,
    Value<String?> category = const Value.absent(),
    String? bodyParts,
    String? targetMuscles,
    String? secondaryMuscles,
    String? equipments,
    Value<String?> difficulty = const Value.absent(),
    Value<String?> gifUrl = const Value.absent(),
    Value<String?> imageUrls = const Value.absent(),
    String? instructions,
    Value<String?> overview = const Value.absent(),
    bool? isCustom,
    int? cachedAt,
  }) => ExercisesCacheData(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category.present ? category.value : this.category,
    bodyParts: bodyParts ?? this.bodyParts,
    targetMuscles: targetMuscles ?? this.targetMuscles,
    secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
    equipments: equipments ?? this.equipments,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    gifUrl: gifUrl.present ? gifUrl.value : this.gifUrl,
    imageUrls: imageUrls.present ? imageUrls.value : this.imageUrls,
    instructions: instructions ?? this.instructions,
    overview: overview.present ? overview.value : this.overview,
    isCustom: isCustom ?? this.isCustom,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ExercisesCacheData copyWithCompanion(ExercisesCacheCompanion data) {
    return ExercisesCacheData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      bodyParts: data.bodyParts.present ? data.bodyParts.value : this.bodyParts,
      targetMuscles: data.targetMuscles.present
          ? data.targetMuscles.value
          : this.targetMuscles,
      secondaryMuscles: data.secondaryMuscles.present
          ? data.secondaryMuscles.value
          : this.secondaryMuscles,
      equipments: data.equipments.present
          ? data.equipments.value
          : this.equipments,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      gifUrl: data.gifUrl.present ? data.gifUrl.value : this.gifUrl,
      imageUrls: data.imageUrls.present ? data.imageUrls.value : this.imageUrls,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      overview: data.overview.present ? data.overview.value : this.overview,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCacheData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('bodyParts: $bodyParts, ')
          ..write('targetMuscles: $targetMuscles, ')
          ..write('secondaryMuscles: $secondaryMuscles, ')
          ..write('equipments: $equipments, ')
          ..write('difficulty: $difficulty, ')
          ..write('gifUrl: $gifUrl, ')
          ..write('imageUrls: $imageUrls, ')
          ..write('instructions: $instructions, ')
          ..write('overview: $overview, ')
          ..write('isCustom: $isCustom, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    bodyParts,
    targetMuscles,
    secondaryMuscles,
    equipments,
    difficulty,
    gifUrl,
    imageUrls,
    instructions,
    overview,
    isCustom,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExercisesCacheData &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.bodyParts == this.bodyParts &&
          other.targetMuscles == this.targetMuscles &&
          other.secondaryMuscles == this.secondaryMuscles &&
          other.equipments == this.equipments &&
          other.difficulty == this.difficulty &&
          other.gifUrl == this.gifUrl &&
          other.imageUrls == this.imageUrls &&
          other.instructions == this.instructions &&
          other.overview == this.overview &&
          other.isCustom == this.isCustom &&
          other.cachedAt == this.cachedAt);
}

class ExercisesCacheCompanion extends UpdateCompanion<ExercisesCacheData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> category;
  final Value<String> bodyParts;
  final Value<String> targetMuscles;
  final Value<String> secondaryMuscles;
  final Value<String> equipments;
  final Value<String?> difficulty;
  final Value<String?> gifUrl;
  final Value<String?> imageUrls;
  final Value<String> instructions;
  final Value<String?> overview;
  final Value<bool> isCustom;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const ExercisesCacheCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.bodyParts = const Value.absent(),
    this.targetMuscles = const Value.absent(),
    this.secondaryMuscles = const Value.absent(),
    this.equipments = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.gifUrl = const Value.absent(),
    this.imageUrls = const Value.absent(),
    this.instructions = const Value.absent(),
    this.overview = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCacheCompanion.insert({
    required String id,
    required String name,
    this.category = const Value.absent(),
    this.bodyParts = const Value.absent(),
    this.targetMuscles = const Value.absent(),
    this.secondaryMuscles = const Value.absent(),
    this.equipments = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.gifUrl = const Value.absent(),
    this.imageUrls = const Value.absent(),
    this.instructions = const Value.absent(),
    this.overview = const Value.absent(),
    this.isCustom = const Value.absent(),
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<ExercisesCacheData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? bodyParts,
    Expression<String>? targetMuscles,
    Expression<String>? secondaryMuscles,
    Expression<String>? equipments,
    Expression<String>? difficulty,
    Expression<String>? gifUrl,
    Expression<String>? imageUrls,
    Expression<String>? instructions,
    Expression<String>? overview,
    Expression<bool>? isCustom,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (bodyParts != null) 'body_parts': bodyParts,
      if (targetMuscles != null) 'target_muscles': targetMuscles,
      if (secondaryMuscles != null) 'secondary_muscles': secondaryMuscles,
      if (equipments != null) 'equipments': equipments,
      if (difficulty != null) 'difficulty': difficulty,
      if (gifUrl != null) 'gif_url': gifUrl,
      if (imageUrls != null) 'image_urls': imageUrls,
      if (instructions != null) 'instructions': instructions,
      if (overview != null) 'overview': overview,
      if (isCustom != null) 'is_custom': isCustom,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? category,
    Value<String>? bodyParts,
    Value<String>? targetMuscles,
    Value<String>? secondaryMuscles,
    Value<String>? equipments,
    Value<String?>? difficulty,
    Value<String?>? gifUrl,
    Value<String?>? imageUrls,
    Value<String>? instructions,
    Value<String?>? overview,
    Value<bool>? isCustom,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return ExercisesCacheCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      bodyParts: bodyParts ?? this.bodyParts,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipments: equipments ?? this.equipments,
      difficulty: difficulty ?? this.difficulty,
      gifUrl: gifUrl ?? this.gifUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      instructions: instructions ?? this.instructions,
      overview: overview ?? this.overview,
      isCustom: isCustom ?? this.isCustom,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (bodyParts.present) {
      map['body_parts'] = Variable<String>(bodyParts.value);
    }
    if (targetMuscles.present) {
      map['target_muscles'] = Variable<String>(targetMuscles.value);
    }
    if (secondaryMuscles.present) {
      map['secondary_muscles'] = Variable<String>(secondaryMuscles.value);
    }
    if (equipments.present) {
      map['equipments'] = Variable<String>(equipments.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (gifUrl.present) {
      map['gif_url'] = Variable<String>(gifUrl.value);
    }
    if (imageUrls.present) {
      map['image_urls'] = Variable<String>(imageUrls.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCacheCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('bodyParts: $bodyParts, ')
          ..write('targetMuscles: $targetMuscles, ')
          ..write('secondaryMuscles: $secondaryMuscles, ')
          ..write('equipments: $equipments, ')
          ..write('difficulty: $difficulty, ')
          ..write('gifUrl: $gifUrl, ')
          ..write('imageUrls: $imageUrls, ')
          ..write('instructions: $instructions, ')
          ..write('overview: $overview, ')
          ..write('isCustom: $isCustom, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesCacheTable extends WorkoutTemplatesCache
    with TableInfo<$WorkoutTemplatesCacheTable, WorkoutTemplatesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinsMeta = const VerificationMeta(
    'durationMins',
  );
  @override
  late final GeneratedColumn<int> durationMins = GeneratedColumn<int>(
    'duration_mins',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exercisesJsonMeta = const VerificationMeta(
    'exercisesJson',
  );
  @override
  late final GeneratedColumn<String> exercisesJson = GeneratedColumn<String>(
    'exercises_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<int> cachedAt = GeneratedColumn<int>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    category,
    difficulty,
    durationMins,
    source,
    imageUrl,
    exercisesJson,
    isActive,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplatesCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('duration_mins')) {
      context.handle(
        _durationMinsMeta,
        durationMins.isAcceptableOrUnknown(
          data['duration_mins']!,
          _durationMinsMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('exercises_json')) {
      context.handle(
        _exercisesJsonMeta,
        exercisesJson.isAcceptableOrUnknown(
          data['exercises_json']!,
          _exercisesJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplatesCacheData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplatesCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      ),
      durationMins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_mins'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      exercisesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercises_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $WorkoutTemplatesCacheTable createAlias(String alias) {
    return $WorkoutTemplatesCacheTable(attachedDatabase, alias);
  }
}

class WorkoutTemplatesCacheData extends DataClass
    implements Insertable<WorkoutTemplatesCacheData> {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? difficulty;
  final int? durationMins;
  final String source;
  final String? imageUrl;
  final String exercisesJson;
  final bool isActive;
  final int cachedAt;
  const WorkoutTemplatesCacheData({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.difficulty,
    this.durationMins,
    required this.source,
    this.imageUrl,
    required this.exercisesJson,
    required this.isActive,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || difficulty != null) {
      map['difficulty'] = Variable<String>(difficulty);
    }
    if (!nullToAbsent || durationMins != null) {
      map['duration_mins'] = Variable<int>(durationMins);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['exercises_json'] = Variable<String>(exercisesJson);
    map['is_active'] = Variable<bool>(isActive);
    map['cached_at'] = Variable<int>(cachedAt);
    return map;
  }

  WorkoutTemplatesCacheCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCacheCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      difficulty: difficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(difficulty),
      durationMins: durationMins == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMins),
      source: Value(source),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      exercisesJson: Value(exercisesJson),
      isActive: Value(isActive),
      cachedAt: Value(cachedAt),
    );
  }

  factory WorkoutTemplatesCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplatesCacheData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String?>(json['category']),
      difficulty: serializer.fromJson<String?>(json['difficulty']),
      durationMins: serializer.fromJson<int?>(json['durationMins']),
      source: serializer.fromJson<String>(json['source']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      exercisesJson: serializer.fromJson<String>(json['exercisesJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      cachedAt: serializer.fromJson<int>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String?>(category),
      'difficulty': serializer.toJson<String?>(difficulty),
      'durationMins': serializer.toJson<int?>(durationMins),
      'source': serializer.toJson<String>(source),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'exercisesJson': serializer.toJson<String>(exercisesJson),
      'isActive': serializer.toJson<bool>(isActive),
      'cachedAt': serializer.toJson<int>(cachedAt),
    };
  }

  WorkoutTemplatesCacheData copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> difficulty = const Value.absent(),
    Value<int?> durationMins = const Value.absent(),
    String? source,
    Value<String?> imageUrl = const Value.absent(),
    String? exercisesJson,
    bool? isActive,
    int? cachedAt,
  }) => WorkoutTemplatesCacheData(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    category: category.present ? category.value : this.category,
    difficulty: difficulty.present ? difficulty.value : this.difficulty,
    durationMins: durationMins.present ? durationMins.value : this.durationMins,
    source: source ?? this.source,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    exercisesJson: exercisesJson ?? this.exercisesJson,
    isActive: isActive ?? this.isActive,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  WorkoutTemplatesCacheData copyWithCompanion(
    WorkoutTemplatesCacheCompanion data,
  ) {
    return WorkoutTemplatesCacheData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      durationMins: data.durationMins.present
          ? data.durationMins.value
          : this.durationMins,
      source: data.source.present ? data.source.value : this.source,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      exercisesJson: data.exercisesJson.present
          ? data.exercisesJson.value
          : this.exercisesJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCacheData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('durationMins: $durationMins, ')
          ..write('source: $source, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('exercisesJson: $exercisesJson, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    category,
    difficulty,
    durationMins,
    source,
    imageUrl,
    exercisesJson,
    isActive,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplatesCacheData &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.difficulty == this.difficulty &&
          other.durationMins == this.durationMins &&
          other.source == this.source &&
          other.imageUrl == this.imageUrl &&
          other.exercisesJson == this.exercisesJson &&
          other.isActive == this.isActive &&
          other.cachedAt == this.cachedAt);
}

class WorkoutTemplatesCacheCompanion
    extends UpdateCompanion<WorkoutTemplatesCacheData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> category;
  final Value<String?> difficulty;
  final Value<int?> durationMins;
  final Value<String> source;
  final Value<String?> imageUrl;
  final Value<String> exercisesJson;
  final Value<bool> isActive;
  final Value<int> cachedAt;
  final Value<int> rowid;
  const WorkoutTemplatesCacheCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.durationMins = const Value.absent(),
    this.source = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.exercisesJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutTemplatesCacheCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.durationMins = const Value.absent(),
    this.source = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.exercisesJson = const Value.absent(),
    this.isActive = const Value.absent(),
    required int cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<WorkoutTemplatesCacheData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? difficulty,
    Expression<int>? durationMins,
    Expression<String>? source,
    Expression<String>? imageUrl,
    Expression<String>? exercisesJson,
    Expression<bool>? isActive,
    Expression<int>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
      if (durationMins != null) 'duration_mins': durationMins,
      if (source != null) 'source': source,
      if (imageUrl != null) 'image_url': imageUrl,
      if (exercisesJson != null) 'exercises_json': exercisesJson,
      if (isActive != null) 'is_active': isActive,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutTemplatesCacheCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? category,
    Value<String?>? difficulty,
    Value<int?>? durationMins,
    Value<String>? source,
    Value<String?>? imageUrl,
    Value<String>? exercisesJson,
    Value<bool>? isActive,
    Value<int>? cachedAt,
    Value<int>? rowid,
  }) {
    return WorkoutTemplatesCacheCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      durationMins: durationMins ?? this.durationMins,
      source: source ?? this.source,
      imageUrl: imageUrl ?? this.imageUrl,
      exercisesJson: exercisesJson ?? this.exercisesJson,
      isActive: isActive ?? this.isActive,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (durationMins.present) {
      map['duration_mins'] = Variable<int>(durationMins.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (exercisesJson.present) {
      map['exercises_json'] = Variable<String>(exercisesJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<int>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCacheCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('durationMins: $durationMins, ')
          ..write('source: $source, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('exercisesJson: $exercisesJson, ')
          ..write('isActive: $isActive, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSessionsTable extends PendingSessions
    with TableInfo<$PendingSessionsTable, PendingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gymIdMeta = const VerificationMeta('gymId');
  @override
  late final GeneratedColumn<String> gymId = GeneratedColumn<String>(
    'gym_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    gymId,
    userId,
    templateId,
    startedAt,
    endedAt,
    notes,
    syncStatus,
    syncError,
    retryCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('gym_id')) {
      context.handle(
        _gymIdMeta,
        gymId.isAcceptableOrUnknown(data['gym_id']!, _gymIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gymIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PendingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSession(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      gymId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gym_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingSessionsTable createAlias(String alias) {
    return $PendingSessionsTable(attachedDatabase, alias);
  }
}

class PendingSession extends DataClass implements Insertable<PendingSession> {
  final String localId;
  final String? serverId;
  final String gymId;
  final String userId;
  final String? templateId;
  final int startedAt;
  final int? endedAt;
  final String? notes;
  final String syncStatus;
  final String? syncError;
  final int retryCount;
  final int createdAt;
  const PendingSession({
    required this.localId,
    this.serverId,
    required this.gymId,
    required this.userId,
    this.templateId,
    required this.startedAt,
    this.endedAt,
    this.notes,
    required this.syncStatus,
    this.syncError,
    required this.retryCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['gym_id'] = Variable<String>(gymId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PendingSessionsCompanion toCompanion(bool nullToAbsent) {
    return PendingSessionsCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      gymId: Value(gymId),
      userId: Value(userId),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncStatus: Value(syncStatus),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory PendingSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSession(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      gymId: serializer.fromJson<String>(json['gymId']),
      userId: serializer.fromJson<String>(json['userId']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'gymId': serializer.toJson<String>(gymId),
      'userId': serializer.toJson<String>(userId),
      'templateId': serializer.toJson<String?>(templateId),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'notes': serializer.toJson<String?>(notes),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'syncError': serializer.toJson<String?>(syncError),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PendingSession copyWith({
    String? localId,
    Value<String?> serverId = const Value.absent(),
    String? gymId,
    String? userId,
    Value<String?> templateId = const Value.absent(),
    int? startedAt,
    Value<int?> endedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? syncStatus,
    Value<String?> syncError = const Value.absent(),
    int? retryCount,
    int? createdAt,
  }) => PendingSession(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    gymId: gymId ?? this.gymId,
    userId: userId ?? this.userId,
    templateId: templateId.present ? templateId.value : this.templateId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    notes: notes.present ? notes.value : this.notes,
    syncStatus: syncStatus ?? this.syncStatus,
    syncError: syncError.present ? syncError.value : this.syncError,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingSession copyWithCompanion(PendingSessionsCompanion data) {
    return PendingSession(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      gymId: data.gymId.present ? data.gymId.value : this.gymId,
      userId: data.userId.present ? data.userId.value : this.userId,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSession(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('gymId: $gymId, ')
          ..write('userId: $userId, ')
          ..write('templateId: $templateId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    serverId,
    gymId,
    userId,
    templateId,
    startedAt,
    endedAt,
    notes,
    syncStatus,
    syncError,
    retryCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSession &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.gymId == this.gymId &&
          other.userId == this.userId &&
          other.templateId == this.templateId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.notes == this.notes &&
          other.syncStatus == this.syncStatus &&
          other.syncError == this.syncError &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class PendingSessionsCompanion extends UpdateCompanion<PendingSession> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String> gymId;
  final Value<String> userId;
  final Value<String?> templateId;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<String?> notes;
  final Value<String> syncStatus;
  final Value<String?> syncError;
  final Value<int> retryCount;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PendingSessionsCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.gymId = const Value.absent(),
    this.userId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingSessionsCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String gymId,
    required String userId,
    this.templateId = const Value.absent(),
    required int startedAt,
    this.endedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.syncError = const Value.absent(),
    this.retryCount = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       gymId = Value(gymId),
       userId = Value(userId),
       startedAt = Value(startedAt),
       createdAt = Value(createdAt);
  static Insertable<PendingSession> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? gymId,
    Expression<String>? userId,
    Expression<String>? templateId,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<String>? notes,
    Expression<String>? syncStatus,
    Expression<String>? syncError,
    Expression<int>? retryCount,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (gymId != null) 'gym_id': gymId,
      if (userId != null) 'user_id': userId,
      if (templateId != null) 'template_id': templateId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (notes != null) 'notes': notes,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (syncError != null) 'sync_error': syncError,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingSessionsCompanion copyWith({
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String>? gymId,
    Value<String>? userId,
    Value<String?>? templateId,
    Value<int>? startedAt,
    Value<int?>? endedAt,
    Value<String?>? notes,
    Value<String>? syncStatus,
    Value<String?>? syncError,
    Value<int>? retryCount,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingSessionsCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      gymId: gymId ?? this.gymId,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (gymId.present) {
      map['gym_id'] = Variable<String>(gymId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSessionsCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('gymId: $gymId, ')
          ..write('userId: $userId, ')
          ..write('templateId: $templateId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('notes: $notes, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('syncError: $syncError, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSetsTable extends PendingSets
    with TableInfo<$PendingSetsTable, PendingSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionLocalIdMeta = const VerificationMeta(
    'sessionLocalId',
  );
  @override
  late final GeneratedColumn<String> sessionLocalId = GeneratedColumn<String>(
    'session_local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionServerIdMeta = const VerificationMeta(
    'sessionServerId',
  );
  @override
  late final GeneratedColumn<String> sessionServerId = GeneratedColumn<String>(
    'session_server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setNumberMeta = const VerificationMeta(
    'setNumber',
  );
  @override
  late final GeneratedColumn<int> setNumber = GeneratedColumn<int>(
    'set_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assistKgMeta = const VerificationMeta(
    'assistKg',
  );
  @override
  late final GeneratedColumn<double> assistKg = GeneratedColumn<double>(
    'assist_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecsMeta = const VerificationMeta(
    'durationSecs',
  );
  @override
  late final GeneratedColumn<int> durationSecs = GeneratedColumn<int>(
    'duration_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedKphMeta = const VerificationMeta(
    'speedKph',
  );
  @override
  late final GeneratedColumn<double> speedKph = GeneratedColumn<double>(
    'speed_kph',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrMeta = const VerificationMeta('isPr');
  @override
  late final GeneratedColumn<bool> isPr = GeneratedColumn<bool>(
    'is_pr',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pr" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    sessionLocalId,
    sessionServerId,
    exerciseId,
    setNumber,
    reps,
    weightKg,
    rpe,
    assistKg,
    durationSecs,
    distanceM,
    speedKph,
    isPr,
    syncStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('session_local_id')) {
      context.handle(
        _sessionLocalIdMeta,
        sessionLocalId.isAcceptableOrUnknown(
          data['session_local_id']!,
          _sessionLocalIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionLocalIdMeta);
    }
    if (data.containsKey('session_server_id')) {
      context.handle(
        _sessionServerIdMeta,
        sessionServerId.isAcceptableOrUnknown(
          data['session_server_id']!,
          _sessionServerIdMeta,
        ),
      );
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_number')) {
      context.handle(
        _setNumberMeta,
        setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('rpe')) {
      context.handle(
        _rpeMeta,
        rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta),
      );
    }
    if (data.containsKey('assist_kg')) {
      context.handle(
        _assistKgMeta,
        assistKg.isAcceptableOrUnknown(data['assist_kg']!, _assistKgMeta),
      );
    }
    if (data.containsKey('duration_secs')) {
      context.handle(
        _durationSecsMeta,
        durationSecs.isAcceptableOrUnknown(
          data['duration_secs']!,
          _durationSecsMeta,
        ),
      );
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    }
    if (data.containsKey('speed_kph')) {
      context.handle(
        _speedKphMeta,
        speedKph.isAcceptableOrUnknown(data['speed_kph']!, _speedKphMeta),
      );
    }
    if (data.containsKey('is_pr')) {
      context.handle(
        _isPrMeta,
        isPr.isAcceptableOrUnknown(data['is_pr']!, _isPrMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PendingSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSet(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      sessionLocalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_local_id'],
      )!,
      sessionServerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_server_id'],
      ),
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      setNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_number'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      rpe: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rpe'],
      ),
      assistKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}assist_kg'],
      ),
      durationSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_secs'],
      ),
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_m'],
      ),
      speedKph: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_kph'],
      ),
      isPr: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pr'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingSetsTable createAlias(String alias) {
    return $PendingSetsTable(attachedDatabase, alias);
  }
}

class PendingSet extends DataClass implements Insertable<PendingSet> {
  final String localId;
  final String? serverId;
  final String sessionLocalId;
  final String? sessionServerId;
  final String exerciseId;
  final int? setNumber;
  final int? reps;
  final double? weightKg;
  final double? rpe;
  final double? assistKg;
  final int? durationSecs;
  final double? distanceM;
  final double? speedKph;
  final bool isPr;
  final String syncStatus;
  final int createdAt;
  const PendingSet({
    required this.localId,
    this.serverId,
    required this.sessionLocalId,
    this.sessionServerId,
    required this.exerciseId,
    this.setNumber,
    this.reps,
    this.weightKg,
    this.rpe,
    this.assistKg,
    this.durationSecs,
    this.distanceM,
    this.speedKph,
    required this.isPr,
    required this.syncStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['session_local_id'] = Variable<String>(sessionLocalId);
    if (!nullToAbsent || sessionServerId != null) {
      map['session_server_id'] = Variable<String>(sessionServerId);
    }
    map['exercise_id'] = Variable<String>(exerciseId);
    if (!nullToAbsent || setNumber != null) {
      map['set_number'] = Variable<int>(setNumber);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || assistKg != null) {
      map['assist_kg'] = Variable<double>(assistKg);
    }
    if (!nullToAbsent || durationSecs != null) {
      map['duration_secs'] = Variable<int>(durationSecs);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    if (!nullToAbsent || speedKph != null) {
      map['speed_kph'] = Variable<double>(speedKph);
    }
    map['is_pr'] = Variable<bool>(isPr);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PendingSetsCompanion toCompanion(bool nullToAbsent) {
    return PendingSetsCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      sessionLocalId: Value(sessionLocalId),
      sessionServerId: sessionServerId == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionServerId),
      exerciseId: Value(exerciseId),
      setNumber: setNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(setNumber),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      assistKg: assistKg == null && nullToAbsent
          ? const Value.absent()
          : Value(assistKg),
      durationSecs: durationSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSecs),
      distanceM: distanceM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceM),
      speedKph: speedKph == null && nullToAbsent
          ? const Value.absent()
          : Value(speedKph),
      isPr: Value(isPr),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory PendingSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSet(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      sessionLocalId: serializer.fromJson<String>(json['sessionLocalId']),
      sessionServerId: serializer.fromJson<String?>(json['sessionServerId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setNumber: serializer.fromJson<int?>(json['setNumber']),
      reps: serializer.fromJson<int?>(json['reps']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      assistKg: serializer.fromJson<double?>(json['assistKg']),
      durationSecs: serializer.fromJson<int?>(json['durationSecs']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
      speedKph: serializer.fromJson<double?>(json['speedKph']),
      isPr: serializer.fromJson<bool>(json['isPr']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'sessionLocalId': serializer.toJson<String>(sessionLocalId),
      'sessionServerId': serializer.toJson<String?>(sessionServerId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setNumber': serializer.toJson<int?>(setNumber),
      'reps': serializer.toJson<int?>(reps),
      'weightKg': serializer.toJson<double?>(weightKg),
      'rpe': serializer.toJson<double?>(rpe),
      'assistKg': serializer.toJson<double?>(assistKg),
      'durationSecs': serializer.toJson<int?>(durationSecs),
      'distanceM': serializer.toJson<double?>(distanceM),
      'speedKph': serializer.toJson<double?>(speedKph),
      'isPr': serializer.toJson<bool>(isPr),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PendingSet copyWith({
    String? localId,
    Value<String?> serverId = const Value.absent(),
    String? sessionLocalId,
    Value<String?> sessionServerId = const Value.absent(),
    String? exerciseId,
    Value<int?> setNumber = const Value.absent(),
    Value<int?> reps = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> rpe = const Value.absent(),
    Value<double?> assistKg = const Value.absent(),
    Value<int?> durationSecs = const Value.absent(),
    Value<double?> distanceM = const Value.absent(),
    Value<double?> speedKph = const Value.absent(),
    bool? isPr,
    String? syncStatus,
    int? createdAt,
  }) => PendingSet(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    sessionLocalId: sessionLocalId ?? this.sessionLocalId,
    sessionServerId: sessionServerId.present
        ? sessionServerId.value
        : this.sessionServerId,
    exerciseId: exerciseId ?? this.exerciseId,
    setNumber: setNumber.present ? setNumber.value : this.setNumber,
    reps: reps.present ? reps.value : this.reps,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    rpe: rpe.present ? rpe.value : this.rpe,
    assistKg: assistKg.present ? assistKg.value : this.assistKg,
    durationSecs: durationSecs.present ? durationSecs.value : this.durationSecs,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    speedKph: speedKph.present ? speedKph.value : this.speedKph,
    isPr: isPr ?? this.isPr,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingSet copyWithCompanion(PendingSetsCompanion data) {
    return PendingSet(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      sessionLocalId: data.sessionLocalId.present
          ? data.sessionLocalId.value
          : this.sessionLocalId,
      sessionServerId: data.sessionServerId.present
          ? data.sessionServerId.value
          : this.sessionServerId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      reps: data.reps.present ? data.reps.value : this.reps,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      assistKg: data.assistKg.present ? data.assistKg.value : this.assistKg,
      durationSecs: data.durationSecs.present
          ? data.durationSecs.value
          : this.durationSecs,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      speedKph: data.speedKph.present ? data.speedKph.value : this.speedKph,
      isPr: data.isPr.present ? data.isPr.value : this.isPr,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSet(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('sessionLocalId: $sessionLocalId, ')
          ..write('sessionServerId: $sessionServerId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setNumber: $setNumber, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('rpe: $rpe, ')
          ..write('assistKg: $assistKg, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('distanceM: $distanceM, ')
          ..write('speedKph: $speedKph, ')
          ..write('isPr: $isPr, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    serverId,
    sessionLocalId,
    sessionServerId,
    exerciseId,
    setNumber,
    reps,
    weightKg,
    rpe,
    assistKg,
    durationSecs,
    distanceM,
    speedKph,
    isPr,
    syncStatus,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSet &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.sessionLocalId == this.sessionLocalId &&
          other.sessionServerId == this.sessionServerId &&
          other.exerciseId == this.exerciseId &&
          other.setNumber == this.setNumber &&
          other.reps == this.reps &&
          other.weightKg == this.weightKg &&
          other.rpe == this.rpe &&
          other.assistKg == this.assistKg &&
          other.durationSecs == this.durationSecs &&
          other.distanceM == this.distanceM &&
          other.speedKph == this.speedKph &&
          other.isPr == this.isPr &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class PendingSetsCompanion extends UpdateCompanion<PendingSet> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String> sessionLocalId;
  final Value<String?> sessionServerId;
  final Value<String> exerciseId;
  final Value<int?> setNumber;
  final Value<int?> reps;
  final Value<double?> weightKg;
  final Value<double?> rpe;
  final Value<double?> assistKg;
  final Value<int?> durationSecs;
  final Value<double?> distanceM;
  final Value<double?> speedKph;
  final Value<bool> isPr;
  final Value<String> syncStatus;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PendingSetsCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.sessionLocalId = const Value.absent(),
    this.sessionServerId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.rpe = const Value.absent(),
    this.assistKg = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.speedKph = const Value.absent(),
    this.isPr = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingSetsCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String sessionLocalId,
    this.sessionServerId = const Value.absent(),
    required String exerciseId,
    this.setNumber = const Value.absent(),
    this.reps = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.rpe = const Value.absent(),
    this.assistKg = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.speedKph = const Value.absent(),
    this.isPr = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       sessionLocalId = Value(sessionLocalId),
       exerciseId = Value(exerciseId),
       createdAt = Value(createdAt);
  static Insertable<PendingSet> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? sessionLocalId,
    Expression<String>? sessionServerId,
    Expression<String>? exerciseId,
    Expression<int>? setNumber,
    Expression<int>? reps,
    Expression<double>? weightKg,
    Expression<double>? rpe,
    Expression<double>? assistKg,
    Expression<int>? durationSecs,
    Expression<double>? distanceM,
    Expression<double>? speedKph,
    Expression<bool>? isPr,
    Expression<String>? syncStatus,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (sessionLocalId != null) 'session_local_id': sessionLocalId,
      if (sessionServerId != null) 'session_server_id': sessionServerId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setNumber != null) 'set_number': setNumber,
      if (reps != null) 'reps': reps,
      if (weightKg != null) 'weight_kg': weightKg,
      if (rpe != null) 'rpe': rpe,
      if (assistKg != null) 'assist_kg': assistKg,
      if (durationSecs != null) 'duration_secs': durationSecs,
      if (distanceM != null) 'distance_m': distanceM,
      if (speedKph != null) 'speed_kph': speedKph,
      if (isPr != null) 'is_pr': isPr,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingSetsCompanion copyWith({
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String>? sessionLocalId,
    Value<String?>? sessionServerId,
    Value<String>? exerciseId,
    Value<int?>? setNumber,
    Value<int?>? reps,
    Value<double?>? weightKg,
    Value<double?>? rpe,
    Value<double?>? assistKg,
    Value<int?>? durationSecs,
    Value<double?>? distanceM,
    Value<double?>? speedKph,
    Value<bool>? isPr,
    Value<String>? syncStatus,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingSetsCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      sessionLocalId: sessionLocalId ?? this.sessionLocalId,
      sessionServerId: sessionServerId ?? this.sessionServerId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      rpe: rpe ?? this.rpe,
      assistKg: assistKg ?? this.assistKg,
      durationSecs: durationSecs ?? this.durationSecs,
      distanceM: distanceM ?? this.distanceM,
      speedKph: speedKph ?? this.speedKph,
      isPr: isPr ?? this.isPr,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (sessionLocalId.present) {
      map['session_local_id'] = Variable<String>(sessionLocalId.value);
    }
    if (sessionServerId.present) {
      map['session_server_id'] = Variable<String>(sessionServerId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<int>(setNumber.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (assistKg.present) {
      map['assist_kg'] = Variable<double>(assistKg.value);
    }
    if (durationSecs.present) {
      map['duration_secs'] = Variable<int>(durationSecs.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (speedKph.present) {
      map['speed_kph'] = Variable<double>(speedKph.value);
    }
    if (isPr.present) {
      map['is_pr'] = Variable<bool>(isPr.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSetsCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('sessionLocalId: $sessionLocalId, ')
          ..write('sessionServerId: $sessionServerId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setNumber: $setNumber, ')
          ..write('reps: $reps, ')
          ..write('weightKg: $weightKg, ')
          ..write('rpe: $rpe, ')
          ..write('assistKg: $assistKg, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('distanceM: $distanceM, ')
          ..write('speedKph: $speedKph, ')
          ..write('isPr: $isPr, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueuedWorkoutSharesTable extends QueuedWorkoutShares
    with TableInfo<$QueuedWorkoutSharesTable, QueuedWorkoutShare> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueuedWorkoutSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    content,
    imagePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queued_workout_shares';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueuedWorkoutShare> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueuedWorkoutShare map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueuedWorkoutShare(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QueuedWorkoutSharesTable createAlias(String alias) {
    return $QueuedWorkoutSharesTable(attachedDatabase, alias);
  }
}

class QueuedWorkoutShare extends DataClass
    implements Insertable<QueuedWorkoutShare> {
  final String id;
  final String sessionId;
  final String? content;
  final String? imagePath;
  final int createdAt;
  const QueuedWorkoutShare({
    required this.id,
    required this.sessionId,
    this.content,
    this.imagePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  QueuedWorkoutSharesCompanion toCompanion(bool nullToAbsent) {
    return QueuedWorkoutSharesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      createdAt: Value(createdAt),
    );
  }

  factory QueuedWorkoutShare.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueuedWorkoutShare(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      content: serializer.fromJson<String?>(json['content']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'content': serializer.toJson<String?>(content),
      'imagePath': serializer.toJson<String?>(imagePath),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  QueuedWorkoutShare copyWith({
    String? id,
    String? sessionId,
    Value<String?> content = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    int? createdAt,
  }) => QueuedWorkoutShare(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    content: content.present ? content.value : this.content,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    createdAt: createdAt ?? this.createdAt,
  );
  QueuedWorkoutShare copyWithCompanion(QueuedWorkoutSharesCompanion data) {
    return QueuedWorkoutShare(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      content: data.content.present ? data.content.value : this.content,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueuedWorkoutShare(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('content: $content, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, content, imagePath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueuedWorkoutShare &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.content == this.content &&
          other.imagePath == this.imagePath &&
          other.createdAt == this.createdAt);
}

class QueuedWorkoutSharesCompanion extends UpdateCompanion<QueuedWorkoutShare> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String?> content;
  final Value<String?> imagePath;
  final Value<int> createdAt;
  final Value<int> rowid;
  const QueuedWorkoutSharesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.content = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueuedWorkoutSharesCompanion.insert({
    required String id,
    required String sessionId,
    this.content = const Value.absent(),
    this.imagePath = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       createdAt = Value(createdAt);
  static Insertable<QueuedWorkoutShare> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? content,
    Expression<String>? imagePath,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (content != null) 'content': content,
      if (imagePath != null) 'image_path': imagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueuedWorkoutSharesCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String?>? content,
    Value<String?>? imagePath,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return QueuedWorkoutSharesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueuedWorkoutSharesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('content: $content, ')
          ..write('imagePath: $imagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecentlyUsedCacheTable extends RecentlyUsedCache
    with TableInfo<$RecentlyUsedCacheTable, RecentlyUsedCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentlyUsedCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<int> usedAt = GeneratedColumn<int>(
    'used_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useCountMeta = const VerificationMeta(
    'useCount',
  );
  @override
  late final GeneratedColumn<int> useCount = GeneratedColumn<int>(
    'use_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [exerciseId, userId, usedAt, useCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recently_used_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentlyUsedCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('used_at')) {
      context.handle(
        _usedAtMeta,
        usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_usedAtMeta);
    }
    if (data.containsKey('use_count')) {
      context.handle(
        _useCountMeta,
        useCount.isAcceptableOrUnknown(data['use_count']!, _useCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {exerciseId, userId};
  @override
  RecentlyUsedCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentlyUsedCacheData(
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      usedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_at'],
      )!,
      useCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}use_count'],
      )!,
    );
  }

  @override
  $RecentlyUsedCacheTable createAlias(String alias) {
    return $RecentlyUsedCacheTable(attachedDatabase, alias);
  }
}

class RecentlyUsedCacheData extends DataClass
    implements Insertable<RecentlyUsedCacheData> {
  final String exerciseId;
  final String userId;
  final int usedAt;
  final int useCount;
  const RecentlyUsedCacheData({
    required this.exerciseId,
    required this.userId,
    required this.usedAt,
    required this.useCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exercise_id'] = Variable<String>(exerciseId);
    map['user_id'] = Variable<String>(userId);
    map['used_at'] = Variable<int>(usedAt);
    map['use_count'] = Variable<int>(useCount);
    return map;
  }

  RecentlyUsedCacheCompanion toCompanion(bool nullToAbsent) {
    return RecentlyUsedCacheCompanion(
      exerciseId: Value(exerciseId),
      userId: Value(userId),
      usedAt: Value(usedAt),
      useCount: Value(useCount),
    );
  }

  factory RecentlyUsedCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentlyUsedCacheData(
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      userId: serializer.fromJson<String>(json['userId']),
      usedAt: serializer.fromJson<int>(json['usedAt']),
      useCount: serializer.fromJson<int>(json['useCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'exerciseId': serializer.toJson<String>(exerciseId),
      'userId': serializer.toJson<String>(userId),
      'usedAt': serializer.toJson<int>(usedAt),
      'useCount': serializer.toJson<int>(useCount),
    };
  }

  RecentlyUsedCacheData copyWith({
    String? exerciseId,
    String? userId,
    int? usedAt,
    int? useCount,
  }) => RecentlyUsedCacheData(
    exerciseId: exerciseId ?? this.exerciseId,
    userId: userId ?? this.userId,
    usedAt: usedAt ?? this.usedAt,
    useCount: useCount ?? this.useCount,
  );
  RecentlyUsedCacheData copyWithCompanion(RecentlyUsedCacheCompanion data) {
    return RecentlyUsedCacheData(
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      userId: data.userId.present ? data.userId.value : this.userId,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
      useCount: data.useCount.present ? data.useCount.value : this.useCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentlyUsedCacheData(')
          ..write('exerciseId: $exerciseId, ')
          ..write('userId: $userId, ')
          ..write('usedAt: $usedAt, ')
          ..write('useCount: $useCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(exerciseId, userId, usedAt, useCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentlyUsedCacheData &&
          other.exerciseId == this.exerciseId &&
          other.userId == this.userId &&
          other.usedAt == this.usedAt &&
          other.useCount == this.useCount);
}

class RecentlyUsedCacheCompanion
    extends UpdateCompanion<RecentlyUsedCacheData> {
  final Value<String> exerciseId;
  final Value<String> userId;
  final Value<int> usedAt;
  final Value<int> useCount;
  final Value<int> rowid;
  const RecentlyUsedCacheCompanion({
    this.exerciseId = const Value.absent(),
    this.userId = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.useCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentlyUsedCacheCompanion.insert({
    required String exerciseId,
    required String userId,
    required int usedAt,
    this.useCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : exerciseId = Value(exerciseId),
       userId = Value(userId),
       usedAt = Value(usedAt);
  static Insertable<RecentlyUsedCacheData> custom({
    Expression<String>? exerciseId,
    Expression<String>? userId,
    Expression<int>? usedAt,
    Expression<int>? useCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (userId != null) 'user_id': userId,
      if (usedAt != null) 'used_at': usedAt,
      if (useCount != null) 'use_count': useCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentlyUsedCacheCompanion copyWith({
    Value<String>? exerciseId,
    Value<String>? userId,
    Value<int>? usedAt,
    Value<int>? useCount,
    Value<int>? rowid,
  }) {
    return RecentlyUsedCacheCompanion(
      exerciseId: exerciseId ?? this.exerciseId,
      userId: userId ?? this.userId,
      usedAt: usedAt ?? this.usedAt,
      useCount: useCount ?? this.useCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<int>(usedAt.value);
    }
    if (useCount.present) {
      map['use_count'] = Variable<int>(useCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentlyUsedCacheCompanion(')
          ..write('exerciseId: $exerciseId, ')
          ..write('userId: $userId, ')
          ..write('usedAt: $usedAt, ')
          ..write('useCount: $useCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesCacheTable exercisesCache = $ExercisesCacheTable(this);
  late final $WorkoutTemplatesCacheTable workoutTemplatesCache =
      $WorkoutTemplatesCacheTable(this);
  late final $PendingSessionsTable pendingSessions = $PendingSessionsTable(
    this,
  );
  late final $PendingSetsTable pendingSets = $PendingSetsTable(this);
  late final $QueuedWorkoutSharesTable queuedWorkoutShares =
      $QueuedWorkoutSharesTable(this);
  late final $RecentlyUsedCacheTable recentlyUsedCache =
      $RecentlyUsedCacheTable(this);
  late final ExercisesDao exercisesDao = ExercisesDao(this as AppDatabase);
  late final SessionsDao sessionsDao = SessionsDao(this as AppDatabase);
  late final TemplatesDao templatesDao = TemplatesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercisesCache,
    workoutTemplatesCache,
    pendingSessions,
    pendingSets,
    queuedWorkoutShares,
    recentlyUsedCache,
  ];
}

typedef $$ExercisesCacheTableCreateCompanionBuilder =
    ExercisesCacheCompanion Function({
      required String id,
      required String name,
      Value<String?> category,
      Value<String> bodyParts,
      Value<String> targetMuscles,
      Value<String> secondaryMuscles,
      Value<String> equipments,
      Value<String?> difficulty,
      Value<String?> gifUrl,
      Value<String?> imageUrls,
      Value<String> instructions,
      Value<String?> overview,
      Value<bool> isCustom,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$ExercisesCacheTableUpdateCompanionBuilder =
    ExercisesCacheCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> category,
      Value<String> bodyParts,
      Value<String> targetMuscles,
      Value<String> secondaryMuscles,
      Value<String> equipments,
      Value<String?> difficulty,
      Value<String?> gifUrl,
      Value<String?> imageUrls,
      Value<String> instructions,
      Value<String?> overview,
      Value<bool> isCustom,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$ExercisesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesCacheTable> {
  $$ExercisesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyParts => $composableBuilder(
    column: $table.bodyParts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetMuscles => $composableBuilder(
    column: $table.targetMuscles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryMuscles => $composableBuilder(
    column: $table.secondaryMuscles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipments => $composableBuilder(
    column: $table.equipments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gifUrl => $composableBuilder(
    column: $table.gifUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrls => $composableBuilder(
    column: $table.imageUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExercisesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesCacheTable> {
  $$ExercisesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyParts => $composableBuilder(
    column: $table.bodyParts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetMuscles => $composableBuilder(
    column: $table.targetMuscles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryMuscles => $composableBuilder(
    column: $table.secondaryMuscles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipments => $composableBuilder(
    column: $table.equipments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gifUrl => $composableBuilder(
    column: $table.gifUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrls => $composableBuilder(
    column: $table.imageUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesCacheTable> {
  $$ExercisesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get bodyParts =>
      $composableBuilder(column: $table.bodyParts, builder: (column) => column);

  GeneratedColumn<String> get targetMuscles => $composableBuilder(
    column: $table.targetMuscles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryMuscles => $composableBuilder(
    column: $table.secondaryMuscles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipments => $composableBuilder(
    column: $table.equipments,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gifUrl =>
      $composableBuilder(column: $table.gifUrl, builder: (column) => column);

  GeneratedColumn<String> get imageUrls =>
      $composableBuilder(column: $table.imageUrls, builder: (column) => column);

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ExercisesCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesCacheTable,
          ExercisesCacheData,
          $$ExercisesCacheTableFilterComposer,
          $$ExercisesCacheTableOrderingComposer,
          $$ExercisesCacheTableAnnotationComposer,
          $$ExercisesCacheTableCreateCompanionBuilder,
          $$ExercisesCacheTableUpdateCompanionBuilder,
          (
            ExercisesCacheData,
            BaseReferences<
              _$AppDatabase,
              $ExercisesCacheTable,
              ExercisesCacheData
            >,
          ),
          ExercisesCacheData,
          PrefetchHooks Function()
        > {
  $$ExercisesCacheTableTableManager(
    _$AppDatabase db,
    $ExercisesCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> bodyParts = const Value.absent(),
                Value<String> targetMuscles = const Value.absent(),
                Value<String> secondaryMuscles = const Value.absent(),
                Value<String> equipments = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<String?> gifUrl = const Value.absent(),
                Value<String?> imageUrls = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCacheCompanion(
                id: id,
                name: name,
                category: category,
                bodyParts: bodyParts,
                targetMuscles: targetMuscles,
                secondaryMuscles: secondaryMuscles,
                equipments: equipments,
                difficulty: difficulty,
                gifUrl: gifUrl,
                imageUrls: imageUrls,
                instructions: instructions,
                overview: overview,
                isCustom: isCustom,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> category = const Value.absent(),
                Value<String> bodyParts = const Value.absent(),
                Value<String> targetMuscles = const Value.absent(),
                Value<String> secondaryMuscles = const Value.absent(),
                Value<String> equipments = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<String?> gifUrl = const Value.absent(),
                Value<String?> imageUrls = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCacheCompanion.insert(
                id: id,
                name: name,
                category: category,
                bodyParts: bodyParts,
                targetMuscles: targetMuscles,
                secondaryMuscles: secondaryMuscles,
                equipments: equipments,
                difficulty: difficulty,
                gifUrl: gifUrl,
                imageUrls: imageUrls,
                instructions: instructions,
                overview: overview,
                isCustom: isCustom,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExercisesCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesCacheTable,
      ExercisesCacheData,
      $$ExercisesCacheTableFilterComposer,
      $$ExercisesCacheTableOrderingComposer,
      $$ExercisesCacheTableAnnotationComposer,
      $$ExercisesCacheTableCreateCompanionBuilder,
      $$ExercisesCacheTableUpdateCompanionBuilder,
      (
        ExercisesCacheData,
        BaseReferences<_$AppDatabase, $ExercisesCacheTable, ExercisesCacheData>,
      ),
      ExercisesCacheData,
      PrefetchHooks Function()
    >;
typedef $$WorkoutTemplatesCacheTableCreateCompanionBuilder =
    WorkoutTemplatesCacheCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<String?> category,
      Value<String?> difficulty,
      Value<int?> durationMins,
      Value<String> source,
      Value<String?> imageUrl,
      Value<String> exercisesJson,
      Value<bool> isActive,
      required int cachedAt,
      Value<int> rowid,
    });
typedef $$WorkoutTemplatesCacheTableUpdateCompanionBuilder =
    WorkoutTemplatesCacheCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> category,
      Value<String?> difficulty,
      Value<int?> durationMins,
      Value<String> source,
      Value<String?> imageUrl,
      Value<String> exercisesJson,
      Value<bool> isActive,
      Value<int> cachedAt,
      Value<int> rowid,
    });

class $$WorkoutTemplatesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesCacheTable> {
  $$WorkoutTemplatesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMins => $composableBuilder(
    column: $table.durationMins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exercisesJson => $composableBuilder(
    column: $table.exercisesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutTemplatesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesCacheTable> {
  $$WorkoutTemplatesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMins => $composableBuilder(
    column: $table.durationMins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exercisesJson => $composableBuilder(
    column: $table.exercisesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutTemplatesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesCacheTable> {
  $$WorkoutTemplatesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMins => $composableBuilder(
    column: $table.durationMins,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get exercisesJson => $composableBuilder(
    column: $table.exercisesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$WorkoutTemplatesCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutTemplatesCacheTable,
          WorkoutTemplatesCacheData,
          $$WorkoutTemplatesCacheTableFilterComposer,
          $$WorkoutTemplatesCacheTableOrderingComposer,
          $$WorkoutTemplatesCacheTableAnnotationComposer,
          $$WorkoutTemplatesCacheTableCreateCompanionBuilder,
          $$WorkoutTemplatesCacheTableUpdateCompanionBuilder,
          (
            WorkoutTemplatesCacheData,
            BaseReferences<
              _$AppDatabase,
              $WorkoutTemplatesCacheTable,
              WorkoutTemplatesCacheData
            >,
          ),
          WorkoutTemplatesCacheData,
          PrefetchHooks Function()
        > {
  $$WorkoutTemplatesCacheTableTableManager(
    _$AppDatabase db,
    $WorkoutTemplatesCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplatesCacheTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WorkoutTemplatesCacheTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkoutTemplatesCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<int?> durationMins = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> exercisesJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutTemplatesCacheCompanion(
                id: id,
                name: name,
                description: description,
                category: category,
                difficulty: difficulty,
                durationMins: durationMins,
                source: source,
                imageUrl: imageUrl,
                exercisesJson: exercisesJson,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> difficulty = const Value.absent(),
                Value<int?> durationMins = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String> exercisesJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => WorkoutTemplatesCacheCompanion.insert(
                id: id,
                name: name,
                description: description,
                category: category,
                difficulty: difficulty,
                durationMins: durationMins,
                source: source,
                imageUrl: imageUrl,
                exercisesJson: exercisesJson,
                isActive: isActive,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutTemplatesCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutTemplatesCacheTable,
      WorkoutTemplatesCacheData,
      $$WorkoutTemplatesCacheTableFilterComposer,
      $$WorkoutTemplatesCacheTableOrderingComposer,
      $$WorkoutTemplatesCacheTableAnnotationComposer,
      $$WorkoutTemplatesCacheTableCreateCompanionBuilder,
      $$WorkoutTemplatesCacheTableUpdateCompanionBuilder,
      (
        WorkoutTemplatesCacheData,
        BaseReferences<
          _$AppDatabase,
          $WorkoutTemplatesCacheTable,
          WorkoutTemplatesCacheData
        >,
      ),
      WorkoutTemplatesCacheData,
      PrefetchHooks Function()
    >;
typedef $$PendingSessionsTableCreateCompanionBuilder =
    PendingSessionsCompanion Function({
      required String localId,
      Value<String?> serverId,
      required String gymId,
      required String userId,
      Value<String?> templateId,
      required int startedAt,
      Value<int?> endedAt,
      Value<String?> notes,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> retryCount,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$PendingSessionsTableUpdateCompanionBuilder =
    PendingSessionsCompanion Function({
      Value<String> localId,
      Value<String?> serverId,
      Value<String> gymId,
      Value<String> userId,
      Value<String?> templateId,
      Value<int> startedAt,
      Value<int?> endedAt,
      Value<String?> notes,
      Value<String> syncStatus,
      Value<String?> syncError,
      Value<int> retryCount,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$PendingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSessionsTable> {
  $$PendingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSessionsTable> {
  $$PendingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gymId => $composableBuilder(
    column: $table.gymId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSessionsTable> {
  $$PendingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get gymId =>
      $composableBuilder(column: $table.gymId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSessionsTable,
          PendingSession,
          $$PendingSessionsTableFilterComposer,
          $$PendingSessionsTableOrderingComposer,
          $$PendingSessionsTableAnnotationComposer,
          $$PendingSessionsTableCreateCompanionBuilder,
          $$PendingSessionsTableUpdateCompanionBuilder,
          (
            PendingSession,
            BaseReferences<
              _$AppDatabase,
              $PendingSessionsTable,
              PendingSession
            >,
          ),
          PendingSession,
          PrefetchHooks Function()
        > {
  $$PendingSessionsTableTableManager(
    _$AppDatabase db,
    $PendingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> gymId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSessionsCompanion(
                localId: localId,
                serverId: serverId,
                gymId: gymId,
                userId: userId,
                templateId: templateId,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
                syncStatus: syncStatus,
                syncError: syncError,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> serverId = const Value.absent(),
                required String gymId,
                required String userId,
                Value<String?> templateId = const Value.absent(),
                required int startedAt,
                Value<int?> endedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingSessionsCompanion.insert(
                localId: localId,
                serverId: serverId,
                gymId: gymId,
                userId: userId,
                templateId: templateId,
                startedAt: startedAt,
                endedAt: endedAt,
                notes: notes,
                syncStatus: syncStatus,
                syncError: syncError,
                retryCount: retryCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSessionsTable,
      PendingSession,
      $$PendingSessionsTableFilterComposer,
      $$PendingSessionsTableOrderingComposer,
      $$PendingSessionsTableAnnotationComposer,
      $$PendingSessionsTableCreateCompanionBuilder,
      $$PendingSessionsTableUpdateCompanionBuilder,
      (
        PendingSession,
        BaseReferences<_$AppDatabase, $PendingSessionsTable, PendingSession>,
      ),
      PendingSession,
      PrefetchHooks Function()
    >;
typedef $$PendingSetsTableCreateCompanionBuilder =
    PendingSetsCompanion Function({
      required String localId,
      Value<String?> serverId,
      required String sessionLocalId,
      Value<String?> sessionServerId,
      required String exerciseId,
      Value<int?> setNumber,
      Value<int?> reps,
      Value<double?> weightKg,
      Value<double?> rpe,
      Value<double?> assistKg,
      Value<int?> durationSecs,
      Value<double?> distanceM,
      Value<double?> speedKph,
      Value<bool> isPr,
      Value<String> syncStatus,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$PendingSetsTableUpdateCompanionBuilder =
    PendingSetsCompanion Function({
      Value<String> localId,
      Value<String?> serverId,
      Value<String> sessionLocalId,
      Value<String?> sessionServerId,
      Value<String> exerciseId,
      Value<int?> setNumber,
      Value<int?> reps,
      Value<double?> weightKg,
      Value<double?> rpe,
      Value<double?> assistKg,
      Value<int?> durationSecs,
      Value<double?> distanceM,
      Value<double?> speedKph,
      Value<bool> isPr,
      Value<String> syncStatus,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$PendingSetsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSetsTable> {
  $$PendingSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionLocalId => $composableBuilder(
    column: $table.sessionLocalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionServerId => $composableBuilder(
    column: $table.sessionServerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get assistKg => $composableBuilder(
    column: $table.assistKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedKph => $composableBuilder(
    column: $table.speedKph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPr => $composableBuilder(
    column: $table.isPr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSetsTable> {
  $$PendingSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionLocalId => $composableBuilder(
    column: $table.sessionLocalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionServerId => $composableBuilder(
    column: $table.sessionServerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rpe => $composableBuilder(
    column: $table.rpe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get assistKg => $composableBuilder(
    column: $table.assistKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedKph => $composableBuilder(
    column: $table.speedKph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPr => $composableBuilder(
    column: $table.isPr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSetsTable> {
  $$PendingSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get sessionLocalId => $composableBuilder(
    column: $table.sessionLocalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionServerId => $composableBuilder(
    column: $table.sessionServerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<double> get assistKg =>
      $composableBuilder(column: $table.assistKg, builder: (column) => column);

  GeneratedColumn<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get speedKph =>
      $composableBuilder(column: $table.speedKph, builder: (column) => column);

  GeneratedColumn<bool> get isPr =>
      $composableBuilder(column: $table.isPr, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSetsTable,
          PendingSet,
          $$PendingSetsTableFilterComposer,
          $$PendingSetsTableOrderingComposer,
          $$PendingSetsTableAnnotationComposer,
          $$PendingSetsTableCreateCompanionBuilder,
          $$PendingSetsTableUpdateCompanionBuilder,
          (
            PendingSet,
            BaseReferences<_$AppDatabase, $PendingSetsTable, PendingSet>,
          ),
          PendingSet,
          PrefetchHooks Function()
        > {
  $$PendingSetsTableTableManager(_$AppDatabase db, $PendingSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> sessionLocalId = const Value.absent(),
                Value<String?> sessionServerId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int?> setNumber = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<double?> assistKg = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<double?> speedKph = const Value.absent(),
                Value<bool> isPr = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSetsCompanion(
                localId: localId,
                serverId: serverId,
                sessionLocalId: sessionLocalId,
                sessionServerId: sessionServerId,
                exerciseId: exerciseId,
                setNumber: setNumber,
                reps: reps,
                weightKg: weightKg,
                rpe: rpe,
                assistKg: assistKg,
                durationSecs: durationSecs,
                distanceM: distanceM,
                speedKph: speedKph,
                isPr: isPr,
                syncStatus: syncStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> serverId = const Value.absent(),
                required String sessionLocalId,
                Value<String?> sessionServerId = const Value.absent(),
                required String exerciseId,
                Value<int?> setNumber = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<double?> assistKg = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<double?> speedKph = const Value.absent(),
                Value<bool> isPr = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingSetsCompanion.insert(
                localId: localId,
                serverId: serverId,
                sessionLocalId: sessionLocalId,
                sessionServerId: sessionServerId,
                exerciseId: exerciseId,
                setNumber: setNumber,
                reps: reps,
                weightKg: weightKg,
                rpe: rpe,
                assistKg: assistKg,
                durationSecs: durationSecs,
                distanceM: distanceM,
                speedKph: speedKph,
                isPr: isPr,
                syncStatus: syncStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSetsTable,
      PendingSet,
      $$PendingSetsTableFilterComposer,
      $$PendingSetsTableOrderingComposer,
      $$PendingSetsTableAnnotationComposer,
      $$PendingSetsTableCreateCompanionBuilder,
      $$PendingSetsTableUpdateCompanionBuilder,
      (
        PendingSet,
        BaseReferences<_$AppDatabase, $PendingSetsTable, PendingSet>,
      ),
      PendingSet,
      PrefetchHooks Function()
    >;
typedef $$QueuedWorkoutSharesTableCreateCompanionBuilder =
    QueuedWorkoutSharesCompanion Function({
      required String id,
      required String sessionId,
      Value<String?> content,
      Value<String?> imagePath,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$QueuedWorkoutSharesTableUpdateCompanionBuilder =
    QueuedWorkoutSharesCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String?> content,
      Value<String?> imagePath,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$QueuedWorkoutSharesTableFilterComposer
    extends Composer<_$AppDatabase, $QueuedWorkoutSharesTable> {
  $$QueuedWorkoutSharesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueuedWorkoutSharesTableOrderingComposer
    extends Composer<_$AppDatabase, $QueuedWorkoutSharesTable> {
  $$QueuedWorkoutSharesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueuedWorkoutSharesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueuedWorkoutSharesTable> {
  $$QueuedWorkoutSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QueuedWorkoutSharesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueuedWorkoutSharesTable,
          QueuedWorkoutShare,
          $$QueuedWorkoutSharesTableFilterComposer,
          $$QueuedWorkoutSharesTableOrderingComposer,
          $$QueuedWorkoutSharesTableAnnotationComposer,
          $$QueuedWorkoutSharesTableCreateCompanionBuilder,
          $$QueuedWorkoutSharesTableUpdateCompanionBuilder,
          (
            QueuedWorkoutShare,
            BaseReferences<
              _$AppDatabase,
              $QueuedWorkoutSharesTable,
              QueuedWorkoutShare
            >,
          ),
          QueuedWorkoutShare,
          PrefetchHooks Function()
        > {
  $$QueuedWorkoutSharesTableTableManager(
    _$AppDatabase db,
    $QueuedWorkoutSharesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueuedWorkoutSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueuedWorkoutSharesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$QueuedWorkoutSharesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedWorkoutSharesCompanion(
                id: id,
                sessionId: sessionId,
                content: content,
                imagePath: imagePath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                Value<String?> content = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => QueuedWorkoutSharesCompanion.insert(
                id: id,
                sessionId: sessionId,
                content: content,
                imagePath: imagePath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueuedWorkoutSharesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueuedWorkoutSharesTable,
      QueuedWorkoutShare,
      $$QueuedWorkoutSharesTableFilterComposer,
      $$QueuedWorkoutSharesTableOrderingComposer,
      $$QueuedWorkoutSharesTableAnnotationComposer,
      $$QueuedWorkoutSharesTableCreateCompanionBuilder,
      $$QueuedWorkoutSharesTableUpdateCompanionBuilder,
      (
        QueuedWorkoutShare,
        BaseReferences<
          _$AppDatabase,
          $QueuedWorkoutSharesTable,
          QueuedWorkoutShare
        >,
      ),
      QueuedWorkoutShare,
      PrefetchHooks Function()
    >;
typedef $$RecentlyUsedCacheTableCreateCompanionBuilder =
    RecentlyUsedCacheCompanion Function({
      required String exerciseId,
      required String userId,
      required int usedAt,
      Value<int> useCount,
      Value<int> rowid,
    });
typedef $$RecentlyUsedCacheTableUpdateCompanionBuilder =
    RecentlyUsedCacheCompanion Function({
      Value<String> exerciseId,
      Value<String> userId,
      Value<int> usedAt,
      Value<int> useCount,
      Value<int> rowid,
    });

class $$RecentlyUsedCacheTableFilterComposer
    extends Composer<_$AppDatabase, $RecentlyUsedCacheTable> {
  $$RecentlyUsedCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentlyUsedCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentlyUsedCacheTable> {
  $$RecentlyUsedCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get useCount => $composableBuilder(
    column: $table.useCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentlyUsedCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentlyUsedCacheTable> {
  $$RecentlyUsedCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);

  GeneratedColumn<int> get useCount =>
      $composableBuilder(column: $table.useCount, builder: (column) => column);
}

class $$RecentlyUsedCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentlyUsedCacheTable,
          RecentlyUsedCacheData,
          $$RecentlyUsedCacheTableFilterComposer,
          $$RecentlyUsedCacheTableOrderingComposer,
          $$RecentlyUsedCacheTableAnnotationComposer,
          $$RecentlyUsedCacheTableCreateCompanionBuilder,
          $$RecentlyUsedCacheTableUpdateCompanionBuilder,
          (
            RecentlyUsedCacheData,
            BaseReferences<
              _$AppDatabase,
              $RecentlyUsedCacheTable,
              RecentlyUsedCacheData
            >,
          ),
          RecentlyUsedCacheData,
          PrefetchHooks Function()
        > {
  $$RecentlyUsedCacheTableTableManager(
    _$AppDatabase db,
    $RecentlyUsedCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentlyUsedCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentlyUsedCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentlyUsedCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> exerciseId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> usedAt = const Value.absent(),
                Value<int> useCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentlyUsedCacheCompanion(
                exerciseId: exerciseId,
                userId: userId,
                usedAt: usedAt,
                useCount: useCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String exerciseId,
                required String userId,
                required int usedAt,
                Value<int> useCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentlyUsedCacheCompanion.insert(
                exerciseId: exerciseId,
                userId: userId,
                usedAt: usedAt,
                useCount: useCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecentlyUsedCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentlyUsedCacheTable,
      RecentlyUsedCacheData,
      $$RecentlyUsedCacheTableFilterComposer,
      $$RecentlyUsedCacheTableOrderingComposer,
      $$RecentlyUsedCacheTableAnnotationComposer,
      $$RecentlyUsedCacheTableCreateCompanionBuilder,
      $$RecentlyUsedCacheTableUpdateCompanionBuilder,
      (
        RecentlyUsedCacheData,
        BaseReferences<
          _$AppDatabase,
          $RecentlyUsedCacheTable,
          RecentlyUsedCacheData
        >,
      ),
      RecentlyUsedCacheData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesCacheTableTableManager get exercisesCache =>
      $$ExercisesCacheTableTableManager(_db, _db.exercisesCache);
  $$WorkoutTemplatesCacheTableTableManager get workoutTemplatesCache =>
      $$WorkoutTemplatesCacheTableTableManager(_db, _db.workoutTemplatesCache);
  $$PendingSessionsTableTableManager get pendingSessions =>
      $$PendingSessionsTableTableManager(_db, _db.pendingSessions);
  $$PendingSetsTableTableManager get pendingSets =>
      $$PendingSetsTableTableManager(_db, _db.pendingSets);
  $$QueuedWorkoutSharesTableTableManager get queuedWorkoutShares =>
      $$QueuedWorkoutSharesTableTableManager(_db, _db.queuedWorkoutShares);
  $$RecentlyUsedCacheTableTableManager get recentlyUsedCache =>
      $$RecentlyUsedCacheTableTableManager(_db, _db.recentlyUsedCache);
}
