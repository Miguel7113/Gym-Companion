import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SocialService } from './social.service';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { StaffAuthGuard } from '../auth/staff-auth.guard';
import { CurrentMember } from '../auth/decorators/current-user.decorator';
import { CurrentStaff } from '../auth/decorators/current-user.decorator';
import { CreatePostDto, CreateCommentDto } from './dto/social.dto';

@Controller('social')
@UseGuards(SupabaseAuthGuard)
export class SocialController {
  constructor(private socialService: SocialService) {}

  // ─── Feed (any authenticated member) ──────────────────────────────────────

  @Get('posts')
  getFeed(
    @CurrentMember() member: { userId: string; gymId: string },
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.socialService.getFeed(
      member.gymId,
      member.userId,
      limit ? parseInt(limit, 10) : 20,
      offset ? parseInt(offset, 10) : 0,
    );
  }

  // ─── Staff: create announcement post ──────────────────────────────────────
  // Uses SupabaseAuthGuard but also checks isStaff flag set by the guard.
  // The guard attaches isStaff based on whether the user's email exists in
  // the gym_staff table for their gymId.

  @Post('posts')
  createPost(
    @CurrentMember() member: { userId: string; gymId: string; isStaff: boolean },
    @Body() dto: CreatePostDto,
  ) {
    if (!member.isStaff) {
      // Members can only share achievements — handled by the auto-post system.
      // Direct post creation is staff-only.
      throw new ForbiddenException('Only staff can create posts directly');
    }
    return this.socialService.createStaffPost(member.userId, member.gymId, dto);
  }

  // ─── Like toggle (any member) ──────────────────────────────────────────────

  @Post('posts/:id/like')
  toggleLike(
    @CurrentMember() member: { userId: string },
    @Param('id') postId: string,
  ) {
    return this.socialService.toggleLike(member.userId, postId);
  }

  // ─── Flag post (any member — queues for moderation) ───────────────────────

  @Post('posts/:id/flag')
  flagPost(
    @CurrentMember() member: { userId: string },
    @Param('id') postId: string,
  ) {
    return this.socialService.flagPost(member.userId, postId);
  }

  // ─── Comments ──────────────────────────────────────────────────────────────

  @Get('posts/:id/comments')
  getComments(@Param('id') postId: string) {
    return this.socialService.getComments(postId);
  }

  @Post('posts/:id/comments')
  createComment(
    @CurrentMember() member: { userId: string },
    @Param('id') postId: string,
    @Body() dto: CreateCommentDto,
  ) {
    return this.socialService.createComment(member.userId, postId, dto);
  }

  @Delete('posts/:postId/comments/:commentId')
  deleteComment(
    @CurrentMember() member: { userId: string },
    @Param('commentId') commentId: string,
  ) {
    return this.socialService.deleteComment(member.userId, commentId);
  }
}
