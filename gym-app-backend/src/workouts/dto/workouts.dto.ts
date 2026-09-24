import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsDateString,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class CreateExerciseDto {
  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  category?: string;
}

export class CreateSessionDto {
  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  templateId?: string;

  /** Client-recorded start time (ISO 8601). Used by offline sync. */
  @IsOptional()
  @IsDateString()
  startedAt?: string;
}

export class UpdateSessionDto {
  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  ended?: boolean;

  /** Client-recorded end time (ISO 8601). Used by offline sync. */
  @IsOptional()
  @IsDateString()
  endedAt?: string;
}

export class CreateSetDto {
  @IsString()
  exerciseId!: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  setNumber?: number;

  // Strength fields
  @IsOptional()
  @IsInt()
  @Min(0)
  reps?: number;

  @IsOptional()
  @IsNumber()
  weightKg?: number;

  @IsOptional()
  @IsNumber()
  rpe?: number;

  @IsOptional()
  @IsNumber()
  assistKg?: number;

  // Cardio fields
  @IsOptional()
  @IsInt()
  @Min(0)
  durationSecs?: number;

  @IsOptional()
  @IsNumber()
  distanceM?: number;

  @IsOptional()
  @IsNumber()
  speedKph?: number;
}

export class SaveExerciseDto {
  @IsString()
  exerciseId!: string;
}

export class SaveProgramDto {
  @IsString()
  templateId!: string;
}

export class UpdateUserProfileDto {
  @IsOptional()
  @IsString()
  displayName?: string;

  @IsOptional()
  @IsString()
  gender?: string;

  @IsOptional()
  @IsNumber()
  bodyWeightKg?: number;

  @IsOptional()
  @IsNumber()
  heightCm?: number;
}

export class RoutineExerciseDto {
  @IsString()
  exerciseId!: string;

  @IsInt()
  @Min(0)
  sortOrder!: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  defaultSets?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  defaultReps?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  defaultWeightKg?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  defaultDurationSecs?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  defaultDistanceM?: number;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  notes?: string;
}

export class CreateRoutineDto {
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  category?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  difficulty?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  durationMins?: number;

  @IsOptional()
  @IsBoolean()
  isShared?: boolean;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RoutineExerciseDto)
  exercises!: RoutineExerciseDto[];
}

export class UpdateRoutineDto {
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  category?: string;

  @IsOptional()
  @IsString()
  @MaxLength(40)
  difficulty?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  durationMins?: number;

  @IsOptional()
  @IsBoolean()
  isShared?: boolean;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RoutineExerciseDto)
  exercises?: RoutineExerciseDto[];
}
