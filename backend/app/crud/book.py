"""
CRUD operations for Book model.
"""
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models import Book
from app.schemas.content import BookCreate, BookUpdate


async def get_all_books(db: AsyncSession) -> List[Book]:
    """
    Get all active books with relations.

    Args:
        db: Database session

    Returns:
        List of Book objects
    """
    result = await db.execute(
        select(Book)
        .where(Book.is_active == True)
        .options(selectinload(Book.theme), selectinload(Book.author))
        .order_by(Book.sort_order, Book.name)
    )
    return list(result.scalars().all())


async def get_book_by_id(db: AsyncSession, book_id: int) -> Optional[Book]:
    """
    Get book by ID with relations.

    Args:
        db: Database session
        book_id: Book ID

    Returns:
        Book object if found, None otherwise
    """
    result = await db.execute(
        select(Book)
        .where(Book.id == book_id)
        .options(selectinload(Book.theme), selectinload(Book.author))
    )
    return result.scalar_one_or_none()


async def create_book(db: AsyncSession, book_data: BookCreate) -> Book:
    """
    Create a new book.

    Args:
        db: Database session
        book_data: Book data

    Returns:
        Created Book object
    """
    book = Book(**book_data.model_dump())
    db.add(book)
    await db.commit()
    await db.refresh(book)

    # Load relationships
    result = await db.execute(
        select(Book)
        .where(Book.id == book.id)
        .options(selectinload(Book.theme), selectinload(Book.author))
    )
    book = result.scalar_one()

    return book


async def update_book(
    db: AsyncSession, book_id: int, book_data: BookUpdate
) -> Optional[Book]:
    """
    Update book.

    Args:
        db: Database session
        book_id: Book ID
        book_data: Book update data

    Returns:
        Updated Book object if found, None otherwise
    """
    result = await db.execute(select(Book).where(Book.id == book_id))
    book = result.scalar_one_or_none()

    if not book:
        return None

    # Update only provided fields
    update_data = book_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(book, field, value)

    await db.commit()
    await db.refresh(book)

    # Load relationships
    result = await db.execute(
        select(Book)
        .where(Book.id == book.id)
        .options(selectinload(Book.theme), selectinload(Book.author))
    )
    book = result.scalar_one()

    return book


async def delete_book(db: AsyncSession, book_id: int) -> bool:
    """
    Delete book (soft delete by setting is_active=False).

    Args:
        db: Database session
        book_id: Book ID

    Returns:
        True if deleted, False if not found
    """
    result = await db.execute(select(Book).where(Book.id == book_id))
    book = result.scalar_one_or_none()

    if not book:
        return False

    book.is_active = False
    await db.commit()
    return True
