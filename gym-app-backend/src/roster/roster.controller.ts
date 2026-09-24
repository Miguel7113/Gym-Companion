import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { RosterService } from './roster.service';
import { UploadRosterCsvDto } from './dto/upload-roster-csv.dto';
import { RosterEntryDto } from './dto/roster-entry.dto';
import { StaffAuthGuard } from '../auth/staff-auth.guard';
import { CurrentStaff } from '../auth/decorators/current-user.decorator';

@Controller('roster')
@UseGuards(StaffAuthGuard)
export class RosterController {
  constructor(private rosterService: RosterService) {}

  @Post('import-csv')
  importCsv(@CurrentStaff() staff: { gymId: string }, @Body() dto: UploadRosterCsvDto) {
    return this.rosterService.importCsv(staff.gymId, dto.csvContent);
  }

  @Post('entry')
  addEntry(@CurrentStaff() staff: { gymId: string }, @Body() dto: RosterEntryDto) {
    return this.rosterService.addEntry({ ...dto, gymId: staff.gymId });
  }

  @Get('pending/:gymId')
  listPending(
    @CurrentStaff() staff: { gymId: string },
    @Param('gymId') gymId: string,
  ) {
    return this.rosterService.listPending(staff.gymId === gymId ? gymId : staff.gymId);
  }

  @Post('approve/:rosterId')
  approve(
    @CurrentStaff() staff: { gymId: string },
    @Param('rosterId') rosterId: string,
  ) {
    return this.rosterService.approvePending(staff.gymId, rosterId);
  }
}
