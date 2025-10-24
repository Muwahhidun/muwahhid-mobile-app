"""
CRUD operations for LessonSeries model.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models import LessonSeries
from app.schemas.lesson import LessonSeriesCreate, LessonSeriesUpdate


async def get_all_series(db: AsyncSession) -> List[LessonSeries]:
    """
    Get all series with relationships (including inactive for admin panel).

    Args:
        db: Database session

    Returns:
        List of LessonSeries objects
    """
    result = await db.execute(
        select(LessonSeries)
        # ВРЕМЕННО УБРАН ФИЛЬТР для отладки админ-панели
        # .where(LessonSeries.is_active == True)
        .options(
            selectinload(LessonSeries.teacher),
            selectinload(LessonSeries.book),
            selectinload(LessonSeries.theme)
        )
        .order_by(LessonSeries.year.desc(), LessonSeries.order)
    )
    return list(result.scalars().all())


async def create_series(db: AsyncSession, series_data: LessonSeriesCreate) -> LessonSeries:
    """
    Create a new lesson series.

    Args:
        db: Database session
        series_data: Series creation data

    Returns:
        Created LessonSeries object
    """
    series = LessonSeries(**series_data.model_dump())
    db.add(series)
    await db.commit()
    await db.refresh(series)

    # Load relationships
    result = await db.execute(
        select(LessonSeries)
        .where(LessonSeries.id == series.id)
        .options(
            selectinload(LessonSeries.teacher),
            selectinload(LessonSeries.book),
            selectinload(LessonSeries.theme)
        )
    )
    series = result.scalar_one()

    return series


async def update_series(
    db: AsyncSession, series_id: int, series_data: LessonSeriesUpdate
) -> Optional[LessonSeries]:
    """
    Update a lesson series.

    Args:
        db: Database session
        series_id: Series ID
        series_data: Series update data

    Returns:
        Updated LessonSeries object if found, None otherwise
    """
    result = await db.execute(select(LessonSeries).where(LessonSeries.id == series_id))
    series = result.scalar_one_or_none()

    if not series:
        return None

    # Update only provided fields
    update_data = series_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(series, field, value)

    await db.commit()
    await db.refresh(series)

    # Load relationships
    result = await db.execute(
        select(LessonSeries)
        .where(LessonSeries.id == series.id)
        .options(
            selectinload(LessonSeries.teacher),
            selectinload(LessonSeries.book),
            selectinload(LessonSeries.theme)
        )
    )
    series = result.scalar_one()

    return series


async def delete_series(db: AsyncSession, series_id: int) -> bool:
    """
    Delete a lesson series (soft delete by setting is_active=False).

    Args:
        db: Database session
        series_id: Series ID

    Returns:
        True if deleted, False if not found
    """
    result = await db.execute(select(LessonSeries).where(LessonSeries.id == series_id))
    series = result.scalar_one_or_none()

    if not series:
        return False

    series.is_active = False
    await db.commit()
    return True
