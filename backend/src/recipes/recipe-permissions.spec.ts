import { BadRequestException, ForbiddenException } from '@nestjs/common';
import { UserRole } from '../users/entities/user.entity';
import { RecipeStatus, RecipeType } from './entities/recipe.entity';
import {
  assertCanManageRecipe,
  assertPurchasable,
  assertRecipeFieldsAllowed,
  canFavorite,
  visibleRecipeFilters,
} from './recipe-permissions';

describe('recipe permissions', () => {
  describe('visibleRecipeFilters', () => {
    it('defaults strangers to published recipes', () => {
      const communityOnly: { type: RecipeType; status?: RecipeStatus } = {
        type: RecipeType.COMMUNITY,
      };
      expect(visibleRecipeFilters(communityOnly)).toEqual({
        type: RecipeType.COMMUNITY,
        status: RecipeStatus.PUBLISHED,
      });
      expect(
        visibleRecipeFilters({
          creatorId: 'a',
          status: RecipeStatus.PUBLISHED,
        }),
      ).toEqual({ creatorId: 'a', status: RecipeStatus.PUBLISHED });
    });

    it('lets owners see every status of their own recipes', () => {
      expect(
        visibleRecipeFilters(
          { creatorId: 'me', status: RecipeStatus.DRAFT },
          'me',
        ),
      ).toEqual({ creatorId: 'me', status: RecipeStatus.DRAFT });
      expect(visibleRecipeFilters({ creatorId: 'me' }, 'me')).toEqual({
        creatorId: 'me',
      });
    });

    it("refuses other people's unpublished recipes", () => {
      expect(() =>
        visibleRecipeFilters(
          { creatorId: 'a', status: RecipeStatus.DRAFT },
          'me',
        ),
      ).toThrow(ForbiddenException);
      expect(() =>
        visibleRecipeFilters({ status: RecipeStatus.HIDDEN }),
      ).toThrow(ForbiddenException);
    });
  });

  describe('assertRecipeFieldsAllowed', () => {
    const user = { role: UserRole.USER };
    const creator = { role: UserRole.CREATOR };
    const admin = { role: UserRole.ADMIN };

    it('keeps official recipes for creators', () => {
      expect(() =>
        assertRecipeFieldsAllowed({ type: RecipeType.OFFICIAL }, user, {
          changingType: false,
        }),
      ).toThrow(ForbiddenException);
      expect(() =>
        assertRecipeFieldsAllowed({ type: RecipeType.COMMUNITY }, user, {
          changingType: false,
        }),
      ).not.toThrow();
      expect(() =>
        assertRecipeFieldsAllowed({ type: RecipeType.OFFICIAL }, creator, {
          changingType: false,
        }),
      ).not.toThrow();
    });

    it('only lets creators change the type of an existing recipe', () => {
      expect(() =>
        assertRecipeFieldsAllowed({ type: RecipeType.COMMUNITY }, user, {
          changingType: true,
        }),
      ).toThrow(ForbiddenException);
      expect(() =>
        assertRecipeFieldsAllowed({ type: RecipeType.COMMUNITY }, creator, {
          changingType: true,
        }),
      ).not.toThrow();
    });

    it('leaves hiding and rejecting to admins', () => {
      for (const status of [RecipeStatus.HIDDEN, RecipeStatus.REJECTED]) {
        expect(() =>
          assertRecipeFieldsAllowed({ status }, creator, {
            changingType: true,
          }),
        ).toThrow(ForbiddenException);
        expect(() =>
          assertRecipeFieldsAllowed({ status }, admin, { changingType: true }),
        ).not.toThrow();
      }
      expect(() =>
        assertRecipeFieldsAllowed({ status: RecipeStatus.DRAFT }, user, {
          changingType: true,
        }),
      ).not.toThrow();
    });
  });

  it('assertCanManageRecipe allows owners and admins only', () => {
    const recipe = { creatorId: 'owner' };
    expect(() =>
      assertCanManageRecipe(recipe, { id: 'owner', role: UserRole.USER }),
    ).not.toThrow();
    expect(() =>
      assertCanManageRecipe(recipe, { id: 'x', role: UserRole.ADMIN }),
    ).not.toThrow();
    expect(() =>
      assertCanManageRecipe(recipe, { id: 'x', role: UserRole.CREATOR }),
    ).toThrow(ForbiddenException);
  });

  it('assertPurchasable sells only published official recipes of others', () => {
    const forSale = {
      status: RecipeStatus.PUBLISHED,
      type: RecipeType.OFFICIAL,
      creatorId: 'chef',
    };
    expect(() => assertPurchasable(forSale, 'u1')).not.toThrow();
    for (const recipe of [
      { ...forSale, status: RecipeStatus.DRAFT },
      { ...forSale, status: RecipeStatus.REJECTED },
      { ...forSale, type: RecipeType.COMMUNITY },
      { ...forSale, creatorId: 'u1' },
    ]) {
      expect(() => assertPurchasable(recipe, 'u1')).toThrow(
        BadRequestException,
      );
    }
  });

  it('canFavorite allows published recipes and your own drafts', () => {
    expect(
      canFavorite({ status: RecipeStatus.PUBLISHED, creatorId: 'a' }, 'u1'),
    ).toBe(true);
    expect(
      canFavorite({ status: RecipeStatus.DRAFT, creatorId: 'u1' }, 'u1'),
    ).toBe(true);
    expect(
      canFavorite({ status: RecipeStatus.DRAFT, creatorId: 'a' }, 'u1'),
    ).toBe(false);
  });
});
