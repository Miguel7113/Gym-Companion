import { IsInt, IsNumber, IsOptional, IsString, Min, IsBoolean, IsArray, IsDateString } from 'class-validator';

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
