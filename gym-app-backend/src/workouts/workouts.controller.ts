import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { WorkoutsService } from './workouts.service';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { Public } from '../auth/decorators/public.decorator';
import { CurrentMember } from '../auth/decorators/current-user.decorator';
import { CreateExerciseDto } from './dto/create-exercise.dto';
import { CreateSessionDto } from './dto/create-session.dto';
import { UpdateSessionDto } from './dto/update-session.dto';
import {
  CreateRoutineDto,
  CreateSetDto,
  UpdateRoutineDto,
  UpdateUserProfileDto,
} from './dto/workouts.dto';

@Controller()
@UseGuards(SupabaseAuthGuard)
export class WorkoutsController {
  constructor(private workoutsService: WorkoutsService) {}

  // ─── Exercises — public read endpoints ────────────────────────────────────

  @Public()
  @Get('exercises')
  listExercises(
    @Query('q') q?: string,
    @Query('bodyPart') bodyPart?: string,
    @Query('category') category?: string,
    @Query('equipment') equipment?: string,
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('isCustom') isCustom?: string,
  ) {
    return this.workoutsService.listExercises(
      q,
      bodyPart,
      category,
      equipment,
      limit ? parseInt(limit, 10) : 500,
      offset ? parseInt(offset, 10) : 0,
      isCustom === 'true' ? true : isCustom === 'false' ? false : undefined,
    );
  }

  @Public()
  @Get('exercises/body-parts')
  listBodyParts() {
    return this.workoutsService.listBodyParts();
  }

  // Returns all distinct equipment values for the multi-select filter sheet
  @Public()
  @Get('exercises/equipments')
  listEquipments() {
    return this.workoutsService.listEquipments();
  }

  // Must come BEFORE :id route so NestJS doesn't swallow 'body-parts' as an id
  @Public()
  @Get('exercises/:id')
  getExercise(@Param('id') id: string) {
    return this.workoutsService.getExercise(id);
  }

  // ─── Personal routines ────────────────────────────────────────────────────

  @Get('workouts/routines')
  listRoutines(
    @CurrentMember() member: { userId: string; gymId: string },
  ) {
    return this.workoutsService.listRoutines(member.userId, member.gymId);
  }

  @Get('workouts/routines/:id')
  getRoutine(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') id: string,
  ) {
    return this.workoutsService.getRoutine(member.userId, member.gymId, id);
  }

  @Get('workouts/routines/:id/history')
  getRoutineHistory(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') id: string,
  ) {
    return this.workoutsService.getRoutineHistory(
      member.userId,
      member.gymId,
      id,
    );
  }

  @Get('workouts/routines/:id/leaderboard')
  getRoutineLeaderboard(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') id: string,
    @Query('exerciseId') exerciseId: string,
    @Query('metric') metric?: string,
  ) {
    return this.workoutsService.getRoutineLeaderboard(
      member.userId,
      member.gymId,
      id,
      exerciseId,
      metric ?? 'volume',
    );
  }

  @Post('workouts/routines')
  createRoutine(
    @CurrentMember() member: { userId: string; gymId: string },
    @Body() dto: CreateRoutineDto,
  ) {
    return this.workoutsService.createRoutine(
      member.userId,
      member.gymId,
      dto,
    );
  }

  @Patch('workouts/routines/:id')
  updateRoutine(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') id: string,
    @Body() dto: UpdateRoutineDto,
  ) {
    return this.workoutsService.updateRoutine(
      member.userId,
      member.gymId,
      id,
      dto,
    );
  }

  @Delete('workouts/routines/:id')
  deleteRoutine(
    @CurrentMember() member: { userId: string },
    @Param('id') id: string,
  ) {
    return this.workoutsService.deleteRoutine(member.userId, id);
  }

  @Post('workouts/routines/:id/copy')
  copyRoutine(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') id: string,
  ) {
    return this.workoutsService.copyRoutine(member.userId, member.gymId, id);
  }

  @Get('workouts/programs')
  listGymPrograms(
    @CurrentMember() member: { gymId: string },
    @Query('coachUserId') coachUserId?: string,
  ) {
    return this.workoutsService.listGymPrograms(member.gymId, coachUserId);
  }

  @Post('workouts/routines/:id/publish')
  publishRoutine(
    @CurrentMember()
    member: {
      userId: string;
      gymId: string;
      isStaff: boolean;
    },
    @Param('id') id: string,
  ) {
    return this.workoutsService.publishRoutine(
      member.userId,
      member.gymId,
      id,
      member.isStaff,
    );
  }

  @Post('workouts/routines/:id/unpublish')
  unpublishRoutine(
    @CurrentMember()
    member: {
      userId: string;
      gymId: string;
      isStaff: boolean;
    },
    @Param('id') id: string,
  ) {
    return this.workoutsService.unpublishRoutine(
      member.userId,
      member.gymId,
      id,
      member.isStaff,
    );
  }

  @Post('exercises')
  createExercise(
    @CurrentMember() member: { userId: string },
    @Body() dto: CreateExerciseDto,
  ) {
    return this.workoutsService.createExercise(member.userId, dto);
  }

  // ─── Templates (Programs) ──────────────────────────────────────────────────

  @Get('workouts/templates')
  listTemplates(@CurrentMember() member: { gymId: string }) {
    return this.workoutsService.listTemplates(member.gymId);
  }

  @Get('workouts/templates/:id')
  getTemplate(@Param('id') id: string) {
    return this.workoutsService.getTemplate(id);
  }

  // ─── Saved Exercises ───────────────────────────────────────────────────────

  @Get('workouts/saved/exercises')
  getSavedExercises(@CurrentMember() member: { userId: string }) {
    return this.workoutsService.getSavedExercises(member.userId);
  }

  @Post('workouts/saved/exercises/:exerciseId')
  saveExercise(
    @CurrentMember() member: { userId: string },
    @Param('exerciseId') exerciseId: string,
  ) {
    return this.workoutsService.saveExercise(member.userId, exerciseId);
  }

  @Delete('workouts/saved/exercises/:exerciseId')
  unsaveExercise(
    @CurrentMember() member: { userId: string },
    @Param('exerciseId') exerciseId: string,
  ) {
    return this.workoutsService.unsaveExercise(member.userId, exerciseId);
  }

  // ─── Saved Programs ────────────────────────────────────────────────────────

  @Get('workouts/saved/programs')
  getSavedPrograms(@CurrentMember() member: { userId: string }) {
    return this.workoutsService.getSavedPrograms(member.userId);
  }

  @Post('workouts/saved/programs/:templateId')
  saveProgram(
    @CurrentMember() member: { userId: string },
    @Param('templateId') templateId: string,
  ) {
    return this.workoutsService.saveProgram(member.userId, templateId);
  }

  @Delete('workouts/saved/programs/:templateId')
  unsaveProgram(
    @CurrentMember() member: { userId: string },
    @Param('templateId') templateId: string,
  ) {
    return this.workoutsService.unsaveProgram(member.userId, templateId);
  }

  // ─── Recently Used ─────────────────────────────────────────────────────────

  @Get('workouts/recently-used')
  getRecentlyUsed(
    @CurrentMember() member: { userId: string },
    @Query('limit') limit?: string,
  ) {
    return this.workoutsService.getRecentlyUsed(
      member.userId,
      limit ? parseInt(limit, 10) : 10,
    );
  }

  // ─── User Profile ──────────────────────────────────────────────────────────

  @Patch('users/me/profile')
  updateProfile(
    @CurrentMember() member: { userId: string },
    @Body() dto: UpdateUserProfileDto,
  ) {
    return this.workoutsService.updateProfile(member.userId, dto);
  }

  // ─── Sessions ──────────────────────────────────────────────────────────────

  @Post('workouts/sessions')
  createSession(
    @CurrentMember() member: { userId: string; gymId: string },
    @Body() dto: CreateSessionDto,
  ) {
    return this.workoutsService.createSession(member.userId, member.gymId, dto);
  }

  @Post('workouts/sessions/buddy')
  createBuddySession(
    @CurrentMember() member: { userId: string; gymId: string },
    @Body() body: { buddyUserId: string; templateId?: string },
  ) {
    return this.workoutsService.createBuddySession(
      member.userId,
      member.gymId,
      body.buddyUserId,
      body.templateId,
    );
  }

  @Patch('workouts/sessions/:id')
  updateSession(
    @CurrentMember() member: { userId: string },
    @Param('id') id: string,
    @Body() dto: UpdateSessionDto,
  ) {
    return this.workoutsService.updateSession(member.userId, id, dto);
  }

  @Delete('workouts/sessions/:id')
  deleteSession(
    @CurrentMember() member: { userId: string },
    @Param('id') id: string,
  ) {
    return this.workoutsService.deleteSession(member.userId, id);
  }

  @Get('workouts/sessions')
  listSessions(
    @CurrentMember() member: { userId: string },
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.workoutsService.listSessions(
      member.userId,
      limit ? parseInt(limit, 10) : 20,
      offset ? parseInt(offset, 10) : 0,
    );
  }

  // ─── Sets ──────────────────────────────────────────────────────────────────

  @Post('workouts/sessions/:id/sets')
  addSet(
    @CurrentMember() member: { userId: string },
    @Param('id') sessionId: string,
    @Body() dto: CreateSetDto,
  ) {
    return this.workoutsService.addSet(member.userId, sessionId, dto);
  }

  @Delete('workouts/sets/:id')
  deleteSet(
    @CurrentMember() member: { userId: string },
    @Param('id') id: string,
  ) {
    return this.workoutsService.deleteSet(member.userId, id);
  }

  // ─── Progress ──────────────────────────────────────────────────────────────

  @Get('workouts/progress/:exerciseId')
  getProgress(
    @CurrentMember() member: { userId: string },
    @Param('exerciseId') exerciseId: string,
  ) {
    return this.workoutsService.getProgress(member.userId, exerciseId);
  }
}
