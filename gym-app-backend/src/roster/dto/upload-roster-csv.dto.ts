import { IsString, IsUUID } from 'class-validator';

export class UploadRosterCsvDto {
  @IsUUID()
  gymId!: string;

  /** Raw CSV file contents, sent as a string from the admin portal upload form. */
  @IsString()
  csvContent!: string;
}
