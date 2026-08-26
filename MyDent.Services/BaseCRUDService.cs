using MyDent.Model.SearchObjects;
using MyDent.Services.Database;
using FluentValidation;
using FluentValidation.Results;
using Mapster;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace MyDent.Services
{
    /// <summary>
    /// Generic base service for CRUD operations (Create, Read, Update, Delete)
    /// </summary>
    public abstract class BaseCRUDService<TEntity, TResponse, TSearch, TInsertRequest, TUpdateRequest>
        : BaseReadService<TEntity, TResponse, TSearch>
        where TEntity : class
        where TSearch : BaseSearchObject
    {

        protected readonly IValidator<TInsertRequest> _insertValidator;
        protected readonly IValidator<TUpdateRequest> _updateValidator;

        protected BaseCRUDService(MyDentDbContext dbContext, MapsterMapper.IMapper mapper, IValidator<TInsertRequest> insertValidator, IValidator<TUpdateRequest> updateValidator) : base(mapper, dbContext)
        {
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
        }

        /// <summary>
        /// Gets a writable data source for CRUD operations. Override in derived classes.
        /// </summary>


        /// <summary>
        /// Maps an insert request to an entity. Override in derived classes for custom logic.
        /// </summary>
        protected virtual TEntity MapInsertRequestToEntity(TInsertRequest request)
        {
            var entity = _mapper.Map<TEntity>(request ?? throw new ArgumentNullException(nameof(request)));
            return entity;
        }

        /// <summary>
        /// Maps an update request to an existing entity. Override in derived classes for custom logic.
        /// </summary>
        protected virtual void MapUpdateRequestToEntity(TUpdateRequest request, TEntity entity)
        {
            // var config = new TypeAdapterConfig();
            // config.NewConfig<TUpdateRequest, TEntity>()
            //     .IgnoreNullValues(true);
            // new Mapper(config).Map(request, entity);
            _mapper.Map(request, entity);
        }

        /// <summary>
        /// Inserts a new entity into the data source.
        /// </summary>
        public virtual async Task<TResponse> InsertAsync(TInsertRequest request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);
            if (validationResult.IsValid == false)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new FluentValidation.ValidationException(errors);
            }

            var entity = MapInsertRequestToEntity(request);

            // Set the Id property
            var entityType = entity.GetType();
            var idProperty = entityType.GetProperty("Id");
            //idProperty?.SetValue(entity, GenerateNewId());

            // Set CreatedAt if exists
            var createdAtProperty = entityType.GetProperty("CreatedAt");
            if (createdAtProperty?.CanWrite == true)
            {
                createdAtProperty.SetValue(entity, DateTime.UtcNow);
            }

            this._dbContext.Set<TEntity>().Add(entity);
            await this._dbContext.SaveChangesAsync();
            
            return await Task.FromResult(_mapper.Map<TResponse>(entity));
        }

        /// <summary>
        /// Updates an existing entity in the data source.
        /// </summary>
        public virtual async Task<TResponse> UpdateAsync(int id, TUpdateRequest request)
        {
            // Route id is exposed to validators via RootContextData so update validators can
            // run identity-aware checks (e.g. overlap checks that must exclude the current row)
            // even though the update request itself doesn't carry the entity's id.
            var validationContext = new ValidationContext<TUpdateRequest>(request);
            validationContext.RootContextData["Id"] = id;
            var validationResult = await _updateValidator.ValidateAsync(validationContext);
            if (validationResult.IsValid == false)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new FluentValidation.ValidationException(errors);
            }

           
            var entity = await this._dbContext.Set<TEntity>().FindAsync(id);

            if (entity == null)
                throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found.");

            MapUpdateRequestToEntity(request, entity);

            // Update the UpdatedAt timestamp
            var updatedAtProperty = entity.GetType().GetProperty("UpdatedAt");
            if (updatedAtProperty?.CanWrite == true)
            {
                updatedAtProperty.SetValue(entity, DateTime.UtcNow);
            }

            await this._dbContext.SaveChangesAsync();

            return await Task.FromResult(_mapper.Map<TResponse>(entity));
        }

        /// <summary>
        /// Deletes an entity from the data source by id.
        /// </summary>
        public virtual async Task DeleteAsync(int id)
        {
            var entity = await this._dbContext.Set<TEntity>().FindAsync(id);

            if (entity == null)
                throw new KeyNotFoundException($"{typeof(TEntity).Name} with id {id} not found.");

            // Soft-delete: entities that track a lifecycle via IsActive get deactivated, never
            // hard-removed — other tables may still reference their row by FK (e.g. past
            // Appointments pointing at a Doctor/DentalService). Entities with no IsActive property
            // have nothing to preserve (e.g. Asset, DoctorAbsence, DoctorWorkingHours) and fall
            // back to an actual removal.
            var isActiveProperty = entity.GetType().GetProperty("IsActive");
            if (isActiveProperty?.CanWrite == true && isActiveProperty.PropertyType == typeof(bool))
            {
                isActiveProperty.SetValue(entity, false);
            }
            else
            {
                this._dbContext.Set<TEntity>().Remove(entity);
            }

            await this._dbContext.SaveChangesAsync();
        }
    }
}
