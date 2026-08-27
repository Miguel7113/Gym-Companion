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
import { CreateSetDto, UpdateUserProfileDto } from './dto/workouts.dto';

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
